[CmdletBinding()]
param(
    [ValidateSet('Run', 'ValidatePaths')]
    [string]$Action = 'Run',
    [string]$RepoDir = 'E:\bs_innovation',
    [string]$RuntimeRoot = 'E:\bs_innovation_runtime\stage8_k2_white_snr_all_classical_baselines_v2',
    [string]$TaskName = 'BSInnovation-Stage8K2-WACB-V2',
    [string]$PathsFile = ''
)

$ErrorActionPreference = 'Stop'
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Branch = 'work/stage8-k2-white-snr-all-classical-baselines-v1'
$script:CommitTitle = 'docs(stage8-k2): record unified white-SNR all-classical comparison'

function Invoke-GitText {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $output = & git -C $RepoDir @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')`n$output"
    }
    return ($output | Out-String).Trim()
}

function Test-AllowedPath {
    param([string]$Path)
    $normalized = $Path.Replace('\', '/').Trim('"')
    return $normalized -like 'innovation-mining/48_*' -or
        $normalized -like 'innovation-mining/figures/48_*' -or
        $normalized -eq
        'innovation-mining/stage8_execution_prompts/active/022_stage8_k2_white_snr_all_classical_baselines_v2.md' -or
        $normalized -eq
        'innovation-mining/stage8_execution_prompts/archive/completed/022_stage8_k2_white_snr_all_classical_baselines_v2.md' -or
        $normalized -eq 'innovation-mining/stage8_execution_prompts/active/README.md' -or
        $normalized -eq
        'innovation-mining/stage8_execution_prompts/archive/PROMPT_ARCHIVE_MANIFEST.csv' -or
        $normalized -eq 'innovation-mining/00_DOCUMENT_STATUS_INDEX.md'
}

function Assert-AllowedPaths {
    param([string[]]$Paths)
    foreach ($path in $Paths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and
                -not (Test-AllowedPath $path)) {
            throw "Closeout path is outside the authorized scope: $path"
        }
    }
}

function Get-StatusPaths {
    $status = Invoke-GitText status --porcelain=v1 --untracked-files=all
    if ([string]::IsNullOrWhiteSpace($status)) { return @() }
    $paths = @()
    foreach ($line in ($status -split "`r?`n")) {
        $path = $line.Substring(3).Trim('"')
        if ($path.Contains(' -> ')) { $path = ($path -split ' -> ')[-1] }
        $paths += $path
    }
    return $paths
}

function Assert-FinalManifest {
    $path = Join-Path $RepoDir `
        'innovation-mining\48_stage8_k2_white_snr_all_classical_runtime_manifest.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw 'The independently audited runtime manifest is missing.'
    }
    $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if ($manifest.status -ne
            'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE' -or
            $manifest.independent_audit_status -ne 'PASS' -or
            [int]$manifest.independent_reconstruction_match_count -ne 1680 -or
            [int]$manifest.checkpoint_count -ne 1680 -or
            [int]$manifest.new_method_row_count -ne 6720 -or
            [int]$manifest.diagnostic_row_count -ne 6720 -or
            [int]$manifest.all_method_row_count -ne 16800 -or
            [int]$manifest.element_music_applicable_count -ne 1120 -or
            [int]$manifest.gfbss_applicable_count -ne 1260 -or
            [int]$manifest.root_music_applicable_count -ne 630 -or
            [int]$manifest.ls_esprit_applicable_count -ne 630 -or
            [int]$manifest.truth_leakage_count -ne 0 -or
            [int]$manifest.existing_method_rerun_count -ne 0 -or
            [int]$manifest.independent_artifact_hash_match_count -ne 30) {
        throw 'The independent audit manifest does not satisfy closeout gates.'
    }
    return $manifest
}

function Assert-RefsAndProcesses {
    $branch = Invoke-GitText branch --show-current
    $head = Invoke-GitText rev-parse HEAD
    $remote = Invoke-GitText rev-parse `
        'origin/work/stage8-k2-white-snr-all-classical-baselines-v1'
    $refs = @(
        (Invoke-GitText rev-parse `
            'origin/work/stage8-k2-white-snr-classical-baselines-v1'),
        (Invoke-GitText rev-parse 'origin/experiment/stage8-k2-tangent'),
        (Invoke-GitText rev-parse `
            'origin/work/stage8-k2-subspace-baselines-v1'),
        (Invoke-GitText rev-parse 'origin/main'),
        (Invoke-GitText rev-parse `
            'origin/research/stage8-k2-vincent-anchored'))
    $expected = @(
        '224eedb8282b64fec210e77081bc4fc7748c1fc1',
        'd2d59fe550d8999dc8589aa76e52e89736539b66',
        'dcde540e3f3af793c0b8beb18e41a798af64739a',
        '247fad2208e77b04f7062e22b0fd3fd8a81bfc1f',
        'a7139204d717923cb89d0d629b67f1b3ab7ae94d')
    if ($branch -ne $script:Branch -or $head -ne $remote -or
            (Compare-Object $refs $expected -SyncWindow 0)) {
        throw 'Branch or immutable refs changed before closeout.'
    }
    $processes = @(Get-CimInstance Win32_Process)
    $blocked = @($processes | Where-Object {
        $command = [string]$_.CommandLine
        ($_.Name -match '^MATLAB\.exe$' -and
            $command.Contains('stage8_k2_wacb_') -and
            $command.Contains($RuntimeRoot)) -or
        $_.Name -match '^mwpython.*\.exe$' -or
        $command -match 'stage8.*coordinator|coordinator.*stage8'
    })
    $locks = @(Get-ChildItem -LiteralPath $RuntimeRoot -Filter '*.lock' `
        -File -Recurse -ErrorAction SilentlyContinue)
    $temporary = @(Get-ChildItem -LiteralPath $RuntimeRoot -Filter '*.tmp' `
        -File -Recurse -ErrorAction SilentlyContinue)
    if ($blocked.Count -ne 0 -or $locks.Count -ne 0 -or $temporary.Count -ne 0) {
        throw 'MATLAB, mwpython, coordinator, lock, or tmp remains at closeout.'
    }
}

function Write-AllTextAtomic {
    param([string]$Path, [string]$Content)
    $temporary = "$Path.tmp"
    [System.IO.File]::WriteAllText($temporary, $Content, $script:Utf8NoBom)
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Update-CompletionDocuments {
    $activeRoot = Join-Path $RepoDir `
        'innovation-mining\stage8_execution_prompts\active'
    $archiveRoot = Join-Path $RepoDir `
        'innovation-mining\stage8_execution_prompts\archive'
    $source = Join-Path $activeRoot `
        '022_stage8_k2_white_snr_all_classical_baselines_v2.md'
    $destination = Join-Path $archiveRoot `
        'completed\022_stage8_k2_white_snr_all_classical_baselines_v2.md'
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        if (Test-Path -LiteralPath $destination -PathType Leaf) {
            throw 'Both active and archived prompt paths exist.'
        }
        $before = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        Move-Item -LiteralPath $source -Destination $destination
        $after = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
        if ($before -ne $after) { throw 'Prompt archive move changed bytes.' }
    } elseif (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
        throw 'Neither active nor archived prompt exists.'
    }
    $promptHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
    $readme = @'
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE

BRANCH:
work/stage8-k2-white-snr-all-classical-baselines-v1

SOURCE_WHITE_CLASSIC_BRANCH_CHANGED:
false

LONG_TERM_TANGENT_CHANGED:
false

EXISTING_METHOD_RERUN_COUNT:
0

EXECUTION_CONTROL:
SCHEDULED_TASK_COMPLETED_AND_UNREGISTERED

MERGE_BACK:
NOT_AUTHORIZED

NEXT:
USER_REVIEW
'@
    Write-AllTextAtomic (Join-Path $activeRoot 'README.md') `
        ($readme.TrimStart() + [Environment]::NewLine)
    $manifestPath = Join-Path $archiveRoot 'PROMPT_ARCHIVE_MANIFEST.csv'
    $manifest = @(Import-Csv -LiteralPath $manifestPath)
    $originalRelative =
        'innovation-mining/stage8_execution_prompts/active/022_stage8_k2_white_snr_all_classical_baselines_v2.md'
    if (-not ($manifest | Where-Object { $_.original_path -eq $originalRelative })) {
        $manifest += [pscustomobject]@{
            branch_role = 'TANGENT_PRIMARY_AND_CLASSICAL_BASELINES'
            original_path = $originalRelative
            archived_path =
                'innovation-mining/stage8_execution_prompts/archive/completed/022_stage8_k2_white_snr_all_classical_baselines_v2.md'
            archive_status = 'COMPLETED'
            related_evidence = 'innovation-mining/47_*; innovation-mining/48_*; innovation-mining/figures/48_*'
            tracked_before = 'True'
            sha256_before = $promptHash
            sha256_after = $promptHash
            byte_identical = 'True'
            execution_authority = 'False'
            notes = 'COMPLETED;INDEPENDENT_AUDIT_PASS;SCHEDULED_CONTROLLER;NO_EXECUTION_AUTHORITY'
        }
        $temporary = "$manifestPath.tmp"
        $manifest | Export-Csv -LiteralPath $temporary -NoTypeInformation
        Move-Item -LiteralPath $temporary -Destination $manifestPath -Force
    }
    $indexPath = Join-Path $RepoDir 'innovation-mining\00_DOCUMENT_STATUS_INDEX.md'
    $index = Get-Content -LiteralPath $indexPath -Raw
    if (-not $index.Contains('## Unified white-SNR all-classical comparison')) {
        $addition = @'

## Unified white-SNR all-classical comparison

The registered comparison completed on
`work/stage8-k2-white-snr-all-classical-baselines-v1` with 1680 validated
checkpoints, 6720 new-method rows, 6720 diagnostics, 16800 unified plot rows,
56 representative spectra, zero truth leakage, zero existing-method reruns,
and an independent artifact audit PASS. Execution used the bounded 15-minute
Windows Scheduled Task controller, which unregistered itself after push.

The comparison tiers remain scientifically distinct; structural N/A rows are
not failures or Tangent wins. No production selector or threshold was added.

Next:
`USER_REVIEW`
'@
        Write-AllTextAtomic $indexPath ($index.TrimEnd() + $addition +
            [Environment]::NewLine)
    }
}

function Invoke-PushOnly {
    $headTitle = Invoke-GitText log -1 --format=%s
    if ($headTitle -ne $script:CommitTitle) {
        throw 'GIT_PUSH_PENDING is not at the registered result commit.'
    }
    $head = Invoke-GitText rev-parse HEAD
    & git -C $RepoDir push origin `
        "HEAD:refs/heads/$($script:Branch)" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{
            status = 'GIT_PUSH_PENDING'; result_commit = $head
            push_status = 'NETWORK_RETRY_PENDING'
        }
    }
    $remote = Invoke-GitText rev-parse "origin/$($script:Branch)"
    $status = Invoke-GitText status --porcelain=v1 --untracked-files=all
    if ($head -ne $remote -or -not [string]::IsNullOrWhiteSpace($status)) {
        throw 'Push returned without remote equality or a clean tree.'
    }
    return [pscustomobject]@{
        status = 'COMPLETE'; result_commit = $head; push_status = 'PUSHED'
    }
}

function Invoke-Closeout {
    Assert-FinalManifest | Out-Null
    Assert-RefsAndProcesses
    $paths = @(Get-StatusPaths)
    Assert-AllowedPaths $paths
    $headTitle = Invoke-GitText log -1 --format=%s
    if ($headTitle -eq $script:CommitTitle) {
        return Invoke-PushOnly
    }
    Update-CompletionDocuments
    $paths = @(Get-StatusPaths)
    Assert-AllowedPaths $paths
    & git -C $RepoDir add -- `
        ':(glob)innovation-mining/48_*' `
        ':(glob)innovation-mining/figures/48_*' `
        'innovation-mining/stage8_execution_prompts/active/022_stage8_k2_white_snr_all_classical_baselines_v2.md' `
        'innovation-mining/stage8_execution_prompts/archive/completed/022_stage8_k2_white_snr_all_classical_baselines_v2.md' `
        'innovation-mining/stage8_execution_prompts/active/README.md' `
        'innovation-mining/stage8_execution_prompts/archive/PROMPT_ARCHIVE_MANIFEST.csv' `
        'innovation-mining/00_DOCUMENT_STATUS_INDEX.md' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'git add failed during closeout.' }
    $staged = Invoke-GitText diff --cached --name-only
    Assert-AllowedPaths @($staged -split "`r?`n")
    & git -C $RepoDir diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'git diff --cached --check failed.' }
    & git -C $RepoDir commit -m $script:CommitTitle | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Result commit failed.' }
    return Invoke-PushOnly
}

switch ($Action) {
    'ValidatePaths' {
        if ([string]::IsNullOrWhiteSpace($PathsFile)) {
            throw 'ValidatePaths requires -PathsFile.'
        }
        $paths = @(Get-Content -LiteralPath $PathsFile)
        Assert-AllowedPaths $paths
        [pscustomobject]@{ status = 'ALLOWED_PATH_AUDIT_PASS'; path_count = $paths.Count }
    }
    'Run' { Invoke-Closeout }
}
