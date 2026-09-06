[CmdletBinding()]
param([string]$RepoDir='E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8',
    [string]$RuntimeRoot='E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1')
$ErrorActionPreference='Stop'
$branch='experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1'
$task='BSInnovation-Stage8K2-RawTangent-TwoScenarios-L8-V1'
$complete='STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_COMPLETE'
$message='docs(stage8-k2): record two-scenario L8 results'
if ($RepoDir -ne 'E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8' -or
    $RuntimeRoot -ne 'E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1') { throw 'Wrong experiment paths.' }
if ((git -C $RepoDir branch --show-current).Trim() -ne $branch) { throw 'Wrong branch.' }
git -C $RepoDir fetch origin --prune --tags
if ($LASTEXITCODE -ne 0) { throw 'RTC_GIT_RETRY: final remote refresh failed.' }
if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'MATLAB/mwpython still active.' }
$audit=Get-Content (Join-Path $RuntimeRoot 'status\audit_done.json') -Raw | ConvertFrom-Json
$formal=Get-Content (Join-Path $RuntimeRoot 'controller\formal_identity.json') -Raw | ConvertFrom-Json
if (-not $audit.complete -or -not $audit.pass -or $audit.head -ne $formal.head -or $audit.source_hash -ne $formal.source_hash) { throw 'Independent audit identity missing.' }
& (Join-Path $PSScriptRoot 'Stage8K2RTCScope.ps1') -RepoDir $RepoDir -RequirePruned
$head=(git -C $RepoDir rev-parse HEAD).Trim()
$alreadyCommitted=$head -ne $audit.head
if ($alreadyCommitted) {
    if ((git -C $RepoDir rev-parse HEAD^).Trim() -ne $audit.head -or
        (git -C $RepoDir log -1 --format=%s).Trim() -ne $message) { throw 'Unexpected commit after audit.' }
}
$docPaths=@(
    'innovation-mining/stage8_execution_prompts/active/README.md',
    'innovation-mining/stage8_execution_prompts/README.md',
    'innovation-mining/stage8_execution_prompts/archive/60_stage8_k2_raw_tangent_two_scenarios_l8_execution.md'
)
$modified=@(git -C $RepoDir diff --name-only HEAD)
$untracked=@(git -C $RepoDir ls-files --others --exclude-standard)
foreach ($filename in @($modified)+@($untracked)) {
    if ($filename -notmatch '^innovation-mining/(60_stage8_k2_raw_tangent_two_scenarios_|figures/60_)' -and $filename -notin $docPaths) {
        throw "Unexpected closeout change: $filename"
    }
}
$manifestPath=Join-Path $RepoDir 'innovation-mining\60_stage8_k2_raw_tangent_two_scenarios_runtime_manifest.json'
$reportRelative='innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_results.md'
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.code_identity.head -ne $audit.head -or $manifest.code_identity.source_hash -ne $audit.source_hash) { throw 'Result manifest code identity changed.' }
# The audited report is finalized deterministically, making interrupted closeout repeatable.
$reportPath=Join-Path $RepoDir $reportRelative
$report=Get-Content -LiteralPath $reportPath -Raw
$pendingReport=$report.Replace('Status: '+$complete+'; INDEPENDENT_AUDIT=PASS.','Status: COMPUTED_PENDING_AUDIT.')
$pendingBytes=[Text.UTF8Encoding]::new($false).GetBytes($pendingReport)
$sha=[Security.Cryptography.SHA256]::Create()
try { $pendingHash=([BitConverter]::ToString($sha.ComputeHash($pendingBytes))).Replace('-','').ToLowerInvariant() }
finally { $sha.Dispose() }
foreach ($artifact in $manifest.artifacts) {
    $actual=(Get-FileHash -LiteralPath (Join-Path $RepoDir $artifact.path) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $artifact.sha256 -and -not ($artifact.path -eq $reportRelative -and $pendingHash -eq $artifact.sha256)) { throw "Artifact changed: $($artifact.path)" }
}
if (-not $alreadyCommitted) {
    $utf8=[Text.UTF8Encoding]::new($false)
    $report=$pendingReport.Replace('Status: COMPUTED_PENDING_AUDIT.','Status: '+$complete+'; INDEPENDENT_AUDIT=PASS.')
    [IO.File]::WriteAllText($reportPath,$report,$utf8)
    foreach ($artifact in $manifest.artifacts) {
        if ($artifact.path -eq $reportRelative) {
            $artifact.sha256=(Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash.ToLowerInvariant()
            $artifact.bytes=(Get-Item -LiteralPath $reportPath).Length
        }
    }
    $manifest | Add-Member -NotePropertyName status -NotePropertyValue $complete -Force
    $manifest | Add-Member -NotePropertyName independent_audit_status -NotePropertyValue 'PASS' -Force
    $manifest | Add-Member -NotePropertyName nominal_target_max_error_db -NotePropertyValue $audit.nominal_max_error_db -Force
    $manifest | Add-Member -NotePropertyName active_tangent_cache_count -NotePropertyValue 0 -Force
    $manifest | Add-Member -NotePropertyName active_fixed_k2_call_count -NotePropertyValue 0 -Force
    $manifest | Add-Member -NotePropertyName active_correlated_noise_count -NotePropertyValue 0 -Force
    $manifest | Add-Member -NotePropertyName next -NotePropertyValue 'USER_REVIEW' -Force
    $manifest | Add-Member -NotePropertyName merge_back -NotePropertyValue 'NOT_AUTHORIZED' -Force
    [IO.File]::WriteAllText($manifestPath,($manifest | ConvertTo-Json -Depth 20),$utf8)
    $archive=@'
# Completed Stage8 Execution
Protocol: STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_V1.
Status: STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_COMPLETE; INDEPENDENT_AUDIT=PASS.
[Executed prompt and protocol](../../59_stage8_k2_raw_tangent_two_scenarios_l8_protocol.md).
[Results](../../60_stage8_k2_raw_tangent_two_scenarios_results.md).
NO_ACTIVE_STAGE8_EXECUTION / NEXT=USER_REVIEW / MERGE_BACK=NOT_AUTHORIZED.
This archive records completed authorization and authorizes no additional experiment.
'@
    [IO.File]::WriteAllText((Join-Path $RepoDir $docPaths[2]),$archive,$utf8)
    $active=@'
# Active Stage8 Execution
NO_ACTIVE_STAGE8_EXECUTION / NEXT=USER_REVIEW.
MERGE_BACK=NOT_AUTHORIZED.
[Completed execution](../archive/60_stage8_k2_raw_tangent_two_scenarios_l8_execution.md).
[Audited results](../../60_stage8_k2_raw_tangent_two_scenarios_results.md).
'@
    [IO.File]::WriteAllText((Join-Path $RepoDir $docPaths[0]),$active,$utf8)
    $index=@'
# Stage8 Execution Prompt Index
NO_ACTIVE_STAGE8_EXECUTION / NEXT=USER_REVIEW / MERGE_BACK=NOT_AUTHORIZED.
[Completed two-scenario L8 execution](archive/60_stage8_k2_raw_tangent_two_scenarios_l8_execution.md).
[Protocol](../59_stage8_k2_raw_tangent_two_scenarios_l8_protocol.md).
[Audited results](../60_stage8_k2_raw_tangent_two_scenarios_results.md).
Earlier archive records confer no execution authority.
'@
    [IO.File]::WriteAllText((Join-Path $RepoDir $docPaths[1]),$index,$utf8)
    foreach ($artifact in $manifest.artifacts) {
        if ((Get-FileHash -LiteralPath (Join-Path $RepoDir $artifact.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artifact.sha256) { throw "Final artifact hash mismatch: $($artifact.path)" }
    }
    git -C $RepoDir add -- 'innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_*' 'innovation-mining/figures/60_*' $docPaths
    if ($LASTEXITCODE -ne 0) { throw 'RTC_GIT_RETRY: result staging failed.' }
    git -C $RepoDir commit -m $message
    if ($LASTEXITCODE -ne 0) { throw 'RTC_GIT_RETRY: result commit failed.' }
} else {
    if (@(git -C $RepoDir status --porcelain=v1 --untracked-files=all).Count -or
        $manifest.status -ne $complete -or $manifest.independent_audit_status -ne 'PASS') { throw 'Existing result commit is incomplete or dirty.' }
}
git -C $RepoDir push origin $branch
if ($LASTEXITCODE -ne 0) { throw 'RTC_GIT_RETRY: result push failed; existing result commit will be reused.' }
$head=(git -C $RepoDir rev-parse HEAD).Trim()
$remote=(git -C $RepoDir rev-parse "origin/$branch").Trim()
if ($head -ne $remote -or @(git -C $RepoDir status --porcelain=v1 --untracked-files=all).Count) { throw 'Final Git identity failed.' }
if (@(Get-ChildItem -LiteralPath $RuntimeRoot -Recurse -File | Where-Object { $_.Extension -in @('.tmp','.lock') }).Count) { throw 'Temporary files or locks remain.' }
& (Join-Path $PSScriptRoot 'Stage8K2RTCScope.ps1') -RepoDir $RepoDir -RequirePruned
if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $task -Confirm:$false }
if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) { throw 'Scheduled task was not removed.' }
$final=[ordered]@{state='COMPLETE';status=$complete;independent_audit='PASS';result_commit=$head;push=$true;clean=$true;scheduled_task='ABSENT';next='USER_REVIEW';merge_back='NOT_AUTHORIZED'}
$filename=Join-Path $RuntimeRoot 'controller\controller_state.json'
$temporary="$filename.tmp"
if (Test-Path -LiteralPath $temporary) { throw 'Existing closeout temporary state.' }
[IO.File]::WriteAllText($temporary,($final | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
Move-Item -LiteralPath $temporary -Destination $filename -Force
