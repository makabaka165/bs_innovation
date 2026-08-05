[CmdletBinding()]
param(
    [ValidateSet('InstallAndStart', 'Tick', 'Status', 'Uninstall',
        'RecoverFalseDuplicateHardStop')]
    [string]$Action = 'Status',
    [string]$RepoDir = 'E:\bs_innovation',
    [string]$RuntimeRoot = 'E:\bs_innovation_runtime\stage8_k2_white_snr_all_classical_baselines_v2',
    [string]$MatlabExe = 'E:\MATLABR2022b\bin\matlab.exe',
    [string]$TaskName = 'BSInnovation-Stage8K2-WACB-V2',
    [int]$IntervalMinutes = 15,
    [switch]$TestMode,
    [string]$SnapshotPath = ''
)

$ErrorActionPreference = 'Stop'
$script:Protocol = 'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_V2'
$script:Branch = 'work/stage8-k2-white-snr-all-classical-baselines-v1'
$script:FalseDuplicateReason = 'Multiple exact protocol MATLAB processes detected.'
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:ControllerDir = Join-Path $RuntimeRoot 'controller'
$script:StatePath = Join-Path $script:ControllerDir 'controller_state.json'
$script:LatestTickPath = Join-Path $script:ControllerDir 'latest_tick.json'
$script:LatestTickTextPath = Join-Path $script:ControllerDir 'latest_tick.txt'
$script:HistoryPath = Join-Path $script:ControllerDir 'tick_history.jsonl'
$script:LogPath = Join-Path $script:ControllerDir 'controller.log'
$script:FinalStatusPath = Join-Path $script:ControllerDir 'final_status.json'
$script:FinalStatusTextPath = Join-Path $script:ControllerDir 'final_status.txt'
$script:ControllerScript = $PSCommandPath
$script:CloseoutScript = Join-Path (Split-Path $PSCommandPath -Parent) `
    'Stage8K2WACBCloseout.ps1'

function Get-UtcNowText {
    return [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

function Write-JsonAtomic {
    param([string]$Path, [object]$Value)
    $temporary = "$Path.tmp"
    $json = $Value | ConvertTo-Json -Depth 16
    [System.IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine,
        $script:Utf8NoBom)
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Write-TextAtomic {
    param([string]$Path, [string]$Value)
    $temporary = "$Path.tmp"
    [System.IO.File]::WriteAllText($temporary, $Value, $script:Utf8NoBom)
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required JSON file is missing: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-MutexName {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(
            ([System.IO.Path]::GetFullPath($RuntimeRoot).ToLowerInvariant()))
        $digest = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '')
    } finally {
        $sha.Dispose()
    }
    return "Local\BSInnovationStage8K2WACB_$($digest.Substring(0, 24))"
}

function Ensure-ControllerDirectory {
    if (Test-Path -LiteralPath $RuntimeRoot -PathType Leaf) {
        throw 'The fixed runtime root is an existing file.'
    }
    if (-not (Test-Path -LiteralPath $RuntimeRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $RuntimeRoot | Out-Null
    }
    if (-not (Test-Path -LiteralPath $script:ControllerDir -PathType Container)) {
        New-Item -ItemType Directory -Path $script:ControllerDir | Out-Null
    }
    $logs = Join-Path $RuntimeRoot 'logs'
    if (-not (Test-Path -LiteralPath $logs -PathType Container)) {
        New-Item -ItemType Directory -Path $logs | Out-Null
    }
}

function Invoke-GitText {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $output = & git -C $RepoDir @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')`n$output"
    }
    return ($output | Out-String).Trim()
}

function Assert-FormalPreflight {
    if ([System.IO.Path]::GetFullPath($RepoDir) -ne 'E:\bs_innovation' -or
            [System.IO.Path]::GetFullPath($RuntimeRoot) -ne
            'E:\bs_innovation_runtime\stage8_k2_white_snr_all_classical_baselines_v2' -or
            [System.IO.Path]::GetFullPath($MatlabExe) -ne
            'E:\MATLABR2022b\bin\matlab.exe' -or
            $TaskName -ne 'BSInnovation-Stage8K2-WACB-V2' -or
            $IntervalMinutes -ne 15) {
        throw 'Formal controller paths, task name, or interval differ from V2.'
    }
    if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {
        throw 'The fixed MATLAB executable is missing.'
    }
    $head = Invoke-GitText rev-parse HEAD
    $remote = Invoke-GitText rev-parse `
        'origin/work/stage8-k2-white-snr-all-classical-baselines-v1'
    $branch = Invoke-GitText branch --show-current
    $status = Invoke-GitText status --porcelain=v1 --untracked-files=all
    $refs = [ordered]@{
        source = Invoke-GitText rev-parse `
            'origin/work/stage8-k2-white-snr-classical-baselines-v1'
        tangent = Invoke-GitText rev-parse 'origin/experiment/stage8-k2-tangent'
        subspace = Invoke-GitText rev-parse `
            'origin/work/stage8-k2-subspace-baselines-v1'
        main = Invoke-GitText rev-parse 'origin/main'
        research = Invoke-GitText rev-parse `
            'origin/research/stage8-k2-vincent-anchored'
    }
    if ($branch -ne $script:Branch -or $head -ne $remote -or
            -not [string]::IsNullOrWhiteSpace($status) -or
            $refs.source -ne '224eedb8282b64fec210e77081bc4fc7748c1fc1' -or
            $refs.tangent -ne 'd2d59fe550d8999dc8589aa76e52e89736539b66' -or
            $refs.subspace -ne 'dcde540e3f3af793c0b8beb18e41a798af64739a' -or
            $refs.main -ne '247fad2208e77b04f7062e22b0fd3fd8a81bfc1f' -or
            $refs.research -ne 'a7139204d717923cb89d0d629b67f1b3ab7ae94d') {
        throw 'Formal branch, remote, clean tree, or immutable refs failed.'
    }
    $manifest44Path = Join-Path $RepoDir `
        'innovation-mining\44_stage8_k2_white_snr_monte_carlo_runtime_manifest.json'
    $manifest46Path = Join-Path $RepoDir `
        'innovation-mining\46_stage8_k2_white_snr_classical_baseline_runtime_manifest.json'
    $hash44 = (Get-FileHash -LiteralPath $manifest44Path -Algorithm SHA256).Hash
    $hash46 = (Get-FileHash -LiteralPath $manifest46Path -Algorithm SHA256).Hash
    $manifest44 = Read-JsonFile $manifest44Path
    $manifest46 = Read-JsonFile $manifest46Path
    if ($hash44 -ne 'B97589AA81C70BE8D3219299709E568546AEFB963BAD0AF887BD98BBCABAE6A0' -or
            $hash46 -ne 'E9C19DBEEB6B44A45E685DFE8294A88D46AD2B4DD9078B8AF520BE22A27D70E4' -or
            $manifest44.status -ne
            'STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_COMPLETE' -or
            [int]$manifest44.registry_count -ne 1680 -or
            [int]$manifest44.method_row_count -ne 5040 -or
            $manifest46.status -ne
            'STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPARISON_COMPLETE' -or
            $manifest46.independent_audit_status -ne 'PASS' -or
            [int]$manifest46.baseline_row_count -ne 5040) {
        throw 'Evidence 44/46 preflight failed.'
    }
    $matlabTests = Read-JsonFile (Join-Path $script:ControllerDir `
        'matlab_tests_pass.json')
    $scheduledTest = Read-JsonFile (Join-Path $script:ControllerDir `
        'scheduled_controller_test_pass.json')
    if (-not [bool]$matlabTests.pass -or [int]$matlabTests.test_count -ne 12 -or
            -not [bool]$scheduledTest.pass -or
            [int]$scheduledTest.test_count -ne 1) {
        throw 'Formal execution requires the registered 13/13 test attestations.'
    }
    return [pscustomobject]@{
        head = $head
        code_identity = [string]$matlabTests.code_identity
        registry_hash = [string]$matlabTests.registry_hash
        evidence44_identity = [string]$matlabTests.results[0].evidence44_identity
        evidence46_identity = [string]$matlabTests.results[0].evidence46_identity
    }
}

function New-ControllerState {
    param([object]$Preflight)
    $now = Get-UtcNowText
    return [ordered]@{
        protocol = $script:Protocol
        branch = $script:Branch
        formal_head = [string]$Preflight.head
        code_identity = [string]$Preflight.code_identity
        registry_hash = [string]$Preflight.registry_hash
        evidence44_identity = [string]$Preflight.evidence44_identity
        evidence46_identity = [string]$Preflight.evidence46_identity
        state = 'PREPARED'
        last_transition_utc = $now
        last_tick_utc = $now
        task_name = $TaskName
        task_interval_minutes = $IntervalMinutes
        trial_launch_count = 0
        resume_launch_count = 0
        finalization_launch_count = 0
        audit_launch_count = 0
        git_closeout_attempt_count = 0
        active_matlab_pid = 0
        active_matlab_role = 'NONE'
        completed_checkpoints = 0
        remaining_checkpoints = 1680
        median_trial_runtime_sec = $null
        ETA_sec = $null
        last_valid_checkpoint = ''
        element_music_valid_count = 0
        element_music_single_peak_count = 0
        element_music_na_count = 0
        gfbss_elevation_valid_count = 0
        gfbss_end_to_end_valid_count = 0
        root_elevation_valid_count = 0
        root_end_to_end_valid_count = 0
        esprit_elevation_valid_count = 0
        esprit_end_to_end_valid_count = 0
        conditional_az_cml_valid_count = 0
        last_error = ''
        hard_stop_reason = ''
        result_commit = ''
        push_status = 'NOT_STARTED'
        next_automatic_action = 'START_TRIAL_RUNNER'
    }
}

function Get-TestSnapshot {
    if ([string]::IsNullOrWhiteSpace($SnapshotPath)) {
        throw 'TestMode requires -SnapshotPath.'
    }
    return Read-JsonFile $SnapshotPath
}

function Select-LogicalProtocolProcesses {
    param([object[]]$Processes)
    $candidates = @($Processes)
    if ($candidates.Count -le 1) { return $candidates }

    $byId = @{}
    foreach ($candidate in $candidates) {
        $byId[[int]$candidate.ProcessId] = $candidate
    }
    $logical = @($candidates | Where-Object {
        $parentId = if ($_.PSObject.Properties.Name -contains 'ParentProcessId') {
            [int]$_.ParentProcessId
        } else { 0 }
        -not $byId.ContainsKey($parentId) -or
            [string]$byId[$parentId].Role -ne [string]$_.Role
    })
    return $logical
}

function Get-BoundedSnapshot {
    param([object]$State)
    if ($TestMode) {
        $test = Get-TestSnapshot
        $matching = @(Select-LogicalProtocolProcesses @($test.processes))
        return [pscustomobject]@{
            matching_processes = $matching
            all_processes = @($test.processes)
            completed = [int]$test.completed_checkpoints
            tmp_count = [int]$test.tmp_count
            ready = [bool]$test.ready
            hard_stop = [bool]$test.hard_stop
            latest_status = $test.latest_status
            manifest = $test.manifest
            closeout_result = [string]$test.closeout_result
        }
    }
    $allProcesses = @(Get-CimInstance Win32_Process)
    $repoNeedle = [System.IO.Path]::GetFullPath($RepoDir)
    $runtimeNeedle = [System.IO.Path]::GetFullPath($RuntimeRoot)
    $matchingEntries = @($allProcesses | Where-Object {
        $command = [string]$_.CommandLine
        $_.Name -match '^MATLAB\.exe$' -and
        $command.Contains('-singleCompThread') -and
        $command.Contains($repoNeedle) -and $command.Contains($runtimeNeedle) -and
        ($command.Contains('stage8_k2_wacb_run_guarded') -or
            $command.Contains('stage8_k2_wacb_verify_guarded'))
    } | ForEach-Object {
        [pscustomobject]@{
            ProcessId = [int]$_.ProcessId
            ParentProcessId = [int]$_.ParentProcessId
            CommandLine = [string]$_.CommandLine
            Role = if ([string]$_.CommandLine -match 'verify_guarded') {
                'AUDIT'
            } else { 'RUN' }
        }
    })
    $matching = @(Select-LogicalProtocolProcesses $matchingEntries)
    $checkpointDir = Join-Path $RuntimeRoot 'checkpoints'
    $completed = if (Test-Path -LiteralPath $checkpointDir -PathType Container) {
        @(Get-ChildItem -LiteralPath $checkpointDir -Filter '*.mat' -File).Count
    } else { 0 }
    $tmpCount = if (Test-Path -LiteralPath $RuntimeRoot -PathType Container) {
        @(Get-ChildItem -LiteralPath $RuntimeRoot -Filter '*.tmp' -File -Recurse).Count
    } else { 0 }
    $latestPath = Join-Path $RuntimeRoot 'status\latest_status.json'
    $manifestPath = Join-Path $RepoDir `
        'innovation-mining\48_stage8_k2_white_snr_all_classical_runtime_manifest.json'
    $latest = if (Test-Path -LiteralPath $latestPath -PathType Leaf) {
        Read-JsonFile $latestPath
    } else { $null }
    $manifest = if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        Read-JsonFile $manifestPath
    } else { $null }
    return [pscustomobject]@{
        matching_processes = $matching
        all_processes = $allProcesses
        completed = $completed
        tmp_count = $tmpCount
        ready = Test-Path -LiteralPath (Join-Path $RuntimeRoot `
            'ready_to_finalize.mat') -PathType Leaf
        hard_stop = Test-Path -LiteralPath (Join-Path $RuntimeRoot `
            'status\hard_stop.json') -PathType Leaf
        latest_status = $latest
        manifest = $manifest
        closeout_result = ''
    }
}

function Update-StateFromSnapshot {
    param([object]$State, [object]$Snapshot)
    $State.completed_checkpoints = [int]$Snapshot.completed
    $State.remaining_checkpoints = 1680 - [int]$Snapshot.completed
    if ($Snapshot.matching_processes.Count -eq 1) {
        $State.active_matlab_pid = [int]$Snapshot.matching_processes[0].ProcessId
        $State.active_matlab_role = [string]$Snapshot.matching_processes[0].Role
    } else {
        $State.active_matlab_pid = 0
        $State.active_matlab_role = 'NONE'
    }
    if ($null -ne $Snapshot.latest_status) {
        $latest = $Snapshot.latest_status
        foreach ($pair in @(
            @('median_trial_runtime_sec', 'median_trial_sec'),
            @('ETA_sec', 'eta_sec'),
            @('element_music_valid_count', 'element_music_valid_count'),
            @('element_music_single_peak_count', 'element_music_single_peak_count'),
            @('element_music_na_count', 'element_music_na_count'),
            @('gfbss_elevation_valid_count', 'gfbss_elevation_valid_count'),
            @('gfbss_end_to_end_valid_count', 'gfbss_end_to_end_valid_count'),
            @('root_elevation_valid_count', 'root_elevation_valid_count'),
            @('root_end_to_end_valid_count', 'root_end_to_end_valid_count'),
            @('esprit_elevation_valid_count', 'esprit_elevation_valid_count'),
            @('esprit_end_to_end_valid_count', 'esprit_end_to_end_valid_count'),
            @('conditional_az_cml_valid_count', 'conditional_az_cml_valid_count'))) {
            if ($latest.PSObject.Properties.Name -contains $pair[1]) {
                $State.($pair[0]) = $latest.($pair[1])
            }
        }
        if ($latest.PSObject.Properties.Name -contains 'current_trial') {
            $State.last_valid_checkpoint = [string]$latest.current_trial
        }
    }
}

function Convert-ToMatlabLiteral {
    param([string]$Value)
    return $Value.Replace("'", "''")
}

function Start-ProtocolMatlab {
    param([object]$State, [string]$Role)
    if ($TestMode) {
        $State.active_matlab_pid = 9000 + [int]$State.trial_launch_count +
            [int]$State.resume_launch_count + [int]$State.finalization_launch_count +
            [int]$State.audit_launch_count
        $State.active_matlab_role = $Role
        return
    }
    $toolDir = Join-Path $RepoDir `
        'tools\stage8_k2_white_snr_all_classical_baselines\matlab'
    $repoLiteral = Convert-ToMatlabLiteral $RepoDir
    $runtimeLiteral = Convert-ToMatlabLiteral $RuntimeRoot
    $toolLiteral = Convert-ToMatlabLiteral $toolDir
    if ($Role -eq 'AUDIT') {
        $function = 'stage8_k2_wacb_verify_guarded'
        $label = 'audit'
    } else {
        $function = 'stage8_k2_wacb_run_guarded'
        $label = $Role.ToLowerInvariant()
    }
    $expression = "addpath('$toolLiteral');out=$function('$repoLiteral'," +
        "'$runtimeLiteral');disp(out.status);"
    $ordinal = 1 + [int]$State.trial_launch_count +
        [int]$State.resume_launch_count + [int]$State.finalization_launch_count +
        [int]$State.audit_launch_count
    $stdout = Join-Path $RuntimeRoot ('logs\{0}_{1:D3}.log' -f $label, $ordinal)
    $stderr = Join-Path $RuntimeRoot ('logs\{0}_{1:D3}.err.log' -f $label, $ordinal)
    $process = Start-Process -FilePath $MatlabExe -ArgumentList @(
        '-singleCompThread', '-batch', $expression) -WindowStyle Hidden `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    $State.active_matlab_pid = [int]$process.Id
    $State.active_matlab_role = $Role
}

function Set-Transition {
    param([object]$State, [string]$NewState, [string]$Next)
    $State.state = $NewState
    $State.last_transition_utc = Get-UtcNowText
    $State.next_automatic_action = $Next
}

function Set-HardStop {
    param([object]$State, [string]$Reason)
    $State.last_error = $Reason
    $State.hard_stop_reason = $Reason
    Set-Transition $State 'HARD_STOPPED' 'USER_INSPECTION'
}

function Test-AuditManifestPass {
    param([object]$Manifest)
    if ($null -eq $Manifest) { return $false }
    return $Manifest.status -eq
        'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE' -and
        $Manifest.independent_audit_status -eq 'PASS' -and
        [int]$Manifest.checkpoint_count -eq 1680 -and
        [int]$Manifest.new_method_row_count -eq 6720 -and
        [int]$Manifest.diagnostic_row_count -eq 6720 -and
        [int]$Manifest.all_method_row_count -eq 16800 -and
        [int]$Manifest.representative_spectra_count -eq 56 -and
        [int]$Manifest.existing_method_rerun_count -eq 0
}

function Invoke-Closeout {
    param([object]$State, [object]$Snapshot)
    $State.git_closeout_attempt_count = 1 + [int]$State.git_closeout_attempt_count
    if ($TestMode) {
        $status = if ([string]::IsNullOrWhiteSpace($Snapshot.closeout_result)) {
            'COMPLETE'
        } else { [string]$Snapshot.closeout_result }
        return [pscustomobject]@{
            status = $status
            result_commit = 'TEST_COMMIT'
            push_status = if ($status -eq 'COMPLETE') { 'PUSHED' } else { $status }
        }
    }
    return & $script:CloseoutScript -Action Run -RepoDir $RepoDir `
        -RuntimeRoot $RuntimeRoot -TaskName $TaskName
}

function Remove-ProtocolTask {
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    return $null -eq (Get-ScheduledTask -TaskName $TaskName `
        -ErrorAction SilentlyContinue)
}

function Write-TickOutputs {
    param([object]$State, [object]$Snapshot)
    $State.last_tick_utc = Get-UtcNowText
    $tick = [ordered]@{
        protocol = $script:Protocol
        state = $State.state
        completed = $State.completed_checkpoints
        total = 1680
        remaining = $State.remaining_checkpoints
        last_valid_checkpoint = $State.last_valid_checkpoint
        active_matlab_pid = $State.active_matlab_pid
        active_matlab_role = $State.active_matlab_role
        median_trial_runtime_sec = $State.median_trial_runtime_sec
        ETA_sec = $State.ETA_sec
        element_music_valid_count = $State.element_music_valid_count
        element_music_single_peak_count = $State.element_music_single_peak_count
        element_music_na_count = $State.element_music_na_count
        gfbss_elevation_valid_count = $State.gfbss_elevation_valid_count
        gfbss_end_to_end_valid_count = $State.gfbss_end_to_end_valid_count
        root_elevation_valid_count = $State.root_elevation_valid_count
        root_end_to_end_valid_count = $State.root_end_to_end_valid_count
        esprit_elevation_valid_count = $State.esprit_elevation_valid_count
        esprit_end_to_end_valid_count = $State.esprit_end_to_end_valid_count
        conditional_az_cml_valid_count = $State.conditional_az_cml_valid_count
        tmp_count = $Snapshot.tmp_count
        last_error = $State.last_error
        next_automatic_action = $State.next_automatic_action
        last_tick_utc = $State.last_tick_utc
    }
    Write-JsonAtomic $script:StatePath $State
    Write-JsonAtomic $script:LatestTickPath $tick
    $text = @(
        "State: $($tick.state)"
        "Completed: $($tick.completed) / 1680"
        "Remaining: $($tick.remaining)"
        "Last valid checkpoint: $($tick.last_valid_checkpoint)"
        "Active MATLAB PID / role: $($tick.active_matlab_pid) / $($tick.active_matlab_role)"
        "Median trial runtime sec: $($tick.median_trial_runtime_sec)"
        "ETA sec: $($tick.ETA_sec)"
        "Element MUSIC valid/single-peak/N-A: $($tick.element_music_valid_count) / $($tick.element_music_single_peak_count) / $($tick.element_music_na_count)"
        "GFBSS elevation/end-to-end valid: $($tick.gfbss_elevation_valid_count) / $($tick.gfbss_end_to_end_valid_count)"
        "Root elevation/end-to-end valid: $($tick.root_elevation_valid_count) / $($tick.root_end_to_end_valid_count)"
        "ESPRIT elevation/end-to-end valid: $($tick.esprit_elevation_valid_count) / $($tick.esprit_end_to_end_valid_count)"
        "Conditional az CML valid: $($tick.conditional_az_cml_valid_count)"
        "Last error: $($tick.last_error)"
        "Next automatic action: $($tick.next_automatic_action)"
        "Last tick UTC: $($tick.last_tick_utc)"
    ) -join [Environment]::NewLine
    Write-TextAtomic $script:LatestTickTextPath ($text + [Environment]::NewLine)
    [System.IO.File]::AppendAllText($script:HistoryPath,
        (($tick | ConvertTo-Json -Compress -Depth 10) + [Environment]::NewLine),
        $script:Utf8NoBom)
    [System.IO.File]::AppendAllText($script:LogPath,
        "$($State.last_tick_utc) state=$($State.state) completed=$($State.completed_checkpoints) next=$($State.next_automatic_action)" +
        [Environment]::NewLine, $script:Utf8NoBom)
}

function Write-FinalStatus {
    param([object]$State)
    $final = [ordered]@{
        status = 'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE'
        protocol = $script:Protocol
        branch = $script:Branch
        controller_state = 'COMPLETE'
        result_commit = $State.result_commit
        push_status = $State.push_status
        task_name = $TaskName
        task_unregistered = $true
        next = 'USER_REVIEW'
        completed_utc = Get-UtcNowText
    }
    Write-JsonAtomic $script:FinalStatusPath $final
    $text = @(
        $final.status
        "Branch: $($final.branch)"
        "Result commit: $($final.result_commit)"
        "Push: $($final.push_status)"
        'Scheduled task: UNREGISTERED'
        'Next: USER_REVIEW'
    ) -join [Environment]::NewLine
    Write-TextAtomic $script:FinalStatusTextPath ($text + [Environment]::NewLine)
}

function Invoke-Tick {
    Ensure-ControllerDirectory
    $mutex = New-Object System.Threading.Mutex($false, (Get-MutexName))
    $acquired = $false
    try {
        $acquired = $mutex.WaitOne(0)
        if (-not $acquired) {
            return [pscustomobject]@{ status = 'TICK_SKIPPED_MUTEX_BUSY' }
        }
        $state = Read-JsonFile $script:StatePath
        if ($state.protocol -ne $script:Protocol -or $state.branch -ne $script:Branch) {
            throw 'Controller state protocol or branch identity changed.'
        }
        $snapshot = Get-BoundedSnapshot $state
        Update-StateFromSnapshot $state $snapshot
        if ($snapshot.matching_processes.Count -gt 1) {
            Set-HardStop $state $script:FalseDuplicateReason
        } elseif ($snapshot.hard_stop -and $state.state -ne 'HARD_STOPPED') {
            Set-HardStop $state 'MATLAB runner or independent audit wrote hard_stop.json.'
        } else {
            switch ([string]$state.state) {
                'PREPARED' {
                    Start-ProtocolMatlab $state 'TRIAL'
                    $state.trial_launch_count = 1 + [int]$state.trial_launch_count
                    Set-Transition $state 'TRIALS_RUNNING' 'OBSERVE_OR_RESUME_TRIALS'
                }
                'TRIALS_RUNNING' {
                    if ($snapshot.matching_processes.Count -eq 1) {
                        $state.next_automatic_action = 'WAIT_FOR_CURRENT_TRIAL_SESSION'
                    } elseif ([int]$snapshot.completed -lt 1680) {
                        Start-ProtocolMatlab $state 'RESUME'
                        $state.resume_launch_count = 1 + [int]$state.resume_launch_count
                        $state.next_automatic_action = 'OBSERVE_OR_RESUME_TRIALS'
                    } elseif ([int]$snapshot.completed -eq 1680 -and
                            [bool]$snapshot.ready -and [int]$snapshot.tmp_count -eq 0) {
                        Set-Transition $state 'READY_TO_FINALIZE' 'START_FRESH_FINALIZATION'
                    } else {
                        Set-HardStop $state `
                            'Trial session exited without a valid 1680-checkpoint READY state.'
                    }
                }
                'READY_TO_FINALIZE' {
                    if ([int]$snapshot.completed -ne 1680 -or
                            [int]$snapshot.tmp_count -ne 0 -or
                            $snapshot.matching_processes.Count -ne 0) {
                        Set-HardStop $state 'Finalization preconditions changed.'
                    } else {
                        Start-ProtocolMatlab $state 'FINALIZATION'
                        $state.finalization_launch_count = 1 +
                            [int]$state.finalization_launch_count
                        Set-Transition $state 'FINALIZATION_RUNNING' `
                            'WAIT_FOR_FRESH_FINALIZATION'
                    }
                }
                'FINALIZATION_RUNNING' {
                    if ($snapshot.matching_processes.Count -eq 1) {
                        $state.next_automatic_action = 'WAIT_FOR_FRESH_FINALIZATION'
                    } elseif ($null -ne $snapshot.manifest -and
                            $snapshot.manifest.status -eq
                            'FINALIZED_AWAITING_INDEPENDENT_AUDIT') {
                        Set-Transition $state 'READY_FOR_AUDIT' 'START_FRESH_AUDIT'
                    } else {
                        Set-HardStop $state 'Finalization exited without the pending-audit manifest.'
                    }
                }
                'READY_FOR_AUDIT' {
                    if ($snapshot.matching_processes.Count -ne 0) {
                        Set-HardStop $state 'Audit precondition found an active protocol MATLAB.'
                    } else {
                        Start-ProtocolMatlab $state 'AUDIT'
                        $state.audit_launch_count = 1 + [int]$state.audit_launch_count
                        Set-Transition $state 'AUDIT_RUNNING' 'WAIT_FOR_INDEPENDENT_AUDIT'
                    }
                }
                'AUDIT_RUNNING' {
                    if ($snapshot.matching_processes.Count -eq 1) {
                        $state.next_automatic_action = 'WAIT_FOR_INDEPENDENT_AUDIT'
                    } elseif (Test-AuditManifestPass $snapshot.manifest) {
                        Set-Transition $state 'READY_FOR_GIT_CLOSEOUT' 'RUN_GIT_CLOSEOUT'
                    } else {
                        Set-HardStop $state 'Independent audit exited without all PASS gates.'
                    }
                }
                'READY_FOR_GIT_CLOSEOUT' {
                    $closeout = Invoke-Closeout $state $snapshot
                    $state.result_commit = [string]$closeout.result_commit
                    $state.push_status = [string]$closeout.push_status
                    if ($closeout.status -eq 'COMPLETE') {
                        Set-Transition $state 'COMPLETE' 'USER_REVIEW'
                    } elseif ($closeout.status -eq 'GIT_PUSH_PENDING') {
                        Set-Transition $state 'GIT_PUSH_PENDING' 'RETRY_PUSH_ONLY'
                    } else {
                        Set-HardStop $state "Git closeout failed: $($closeout.status)"
                    }
                }
                'GIT_PUSH_PENDING' {
                    $closeout = Invoke-Closeout $state $snapshot
                    $state.result_commit = [string]$closeout.result_commit
                    $state.push_status = [string]$closeout.push_status
                    if ($closeout.status -eq 'COMPLETE') {
                        Set-Transition $state 'COMPLETE' 'USER_REVIEW'
                    } elseif ($closeout.status -ne 'GIT_PUSH_PENDING') {
                        Set-HardStop $state "Push retry failed: $($closeout.status)"
                    }
                }
                'COMPLETE' { $state.next_automatic_action = 'USER_REVIEW' }
                'HARD_STOPPED' { $state.next_automatic_action = 'USER_INSPECTION' }
                default { Set-HardStop $state "Unknown controller state: $($state.state)" }
            }
        }
        Write-TickOutputs $state $snapshot
        if ($state.state -eq 'COMPLETE') {
            $removed = Remove-ProtocolTask
            if ($removed) {
                Write-FinalStatus $state
            } else {
                $state.last_error = 'MANUAL_TASK_REMOVAL_REQUIRED'
                Write-JsonAtomic $script:StatePath $state
            }
        } elseif ($state.state -eq 'HARD_STOPPED') {
            Remove-ProtocolTask | Out-Null
        }
        return [pscustomobject]@{
            status = 'TICK_COMPLETE'
            state = $state.state
            completed = $state.completed_checkpoints
            active_matlab_pid = $state.active_matlab_pid
            next = $state.next_automatic_action
        }
    } finally {
        if ($acquired) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Get-TaskArguments {
    $format = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Action Tick ' +
        '-RepoDir "{1}" -RuntimeRoot "{2}" -MatlabExe "{3}" ' +
        '-TaskName "{4}" -IntervalMinutes {5}'
    return $format -f $script:ControllerScript, $RepoDir, $RuntimeRoot,
        $MatlabExe, $TaskName, $IntervalMinutes
}

function Register-ProtocolTask {
    $expectedArguments = Get-TaskArguments
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        $actualAction = @($existing.Actions)[0]
        if ($actualAction.Execute -notmatch 'powershell(\.exe)?$' -or
                [string]$actualAction.Arguments -ne $expectedArguments) {
            throw 'An incompatible task already uses the fixed task name.'
        }
        return
    }
    $taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument $expectedArguments
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15) `
        -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $principal = New-ScheduledTaskPrincipal -UserId $identity `
        -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $TaskName -Action $taskAction `
        -Trigger $trigger -Settings $settings -Principal $principal `
        -Description 'Stage8 K2 WACB V2 bounded controller tick every 15 minutes.' | Out-Null
}

function Invoke-RecoverFalseDuplicateHardStop {
    Ensure-ControllerDirectory
    $preflight = Assert-FormalPreflight
    $state = Read-JsonFile $script:StatePath
    if ($state.protocol -ne $script:Protocol -or $state.branch -ne $script:Branch -or
            $state.state -ne 'HARD_STOPPED' -or
            $state.hard_stop_reason -ne $script:FalseDuplicateReason) {
        throw 'Controller state is not the recoverable MATLAB parent-child false positive.'
    }

    $snapshot = Get-BoundedSnapshot $state
    $latest = $snapshot.latest_status
    $latestError = if ($null -ne $latest -and
            $latest.PSObject.Properties.Name -contains 'last_error') {
        [string]$latest.last_error
    } else { '' }
    if ($snapshot.matching_processes.Count -ne 1 -or $snapshot.hard_stop -or
            [int]$snapshot.tmp_count -ne 0 -or [int]$snapshot.completed -ge 1680 -or
            $null -eq $latest -or [string]$latest.stage -ne 'TRIALS_RUNNING' -or
            -not [string]::IsNullOrWhiteSpace($latestError)) {
        throw 'False-duplicate recovery preconditions failed.'
    }

    Update-StateFromSnapshot $state $snapshot
    $state.formal_head = [string]$preflight.head
    $state.code_identity = [string]$preflight.code_identity
    $state.registry_hash = [string]$preflight.registry_hash
    $state.evidence44_identity = [string]$preflight.evidence44_identity
    $state.evidence46_identity = [string]$preflight.evidence46_identity
    $state.last_error = ''
    $state.hard_stop_reason = ''
    Set-Transition $state 'TRIALS_RUNNING' 'WAIT_FOR_CURRENT_TRIAL_SESSION'
    Register-ProtocolTask
    Write-TickOutputs $state $snapshot
    return [pscustomobject]@{
        status = 'FALSE_DUPLICATE_HARD_STOP_RECOVERED'
        state = $state.state
        completed = $state.completed_checkpoints
        active_matlab_pid = $state.active_matlab_pid
        task_name = $TaskName
    }
}

function Invoke-InstallAndStart {
    Ensure-ControllerDirectory
    $preflight = Assert-FormalPreflight
    if (Test-Path -LiteralPath $script:StatePath -PathType Leaf) {
        $existingState = Read-JsonFile $script:StatePath
        if ($existingState.protocol -ne $script:Protocol -or
                $existingState.formal_head -ne $preflight.head -or
                $existingState.state -notin @('PREPARED', 'TRIALS_RUNNING')) {
            throw 'Existing controller state is incompatible with InstallAndStart.'
        }
    } else {
        Write-JsonAtomic $script:StatePath (New-ControllerState $preflight)
    }
    Register-ProtocolTask
    $tick = Invoke-Tick
    $state = Read-JsonFile $script:StatePath
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    $processes = @(Get-CimInstance Win32_Process | Where-Object {
        [int]$_.ProcessId -eq [int]$state.active_matlab_pid -and
        [string]$_.CommandLine -match 'stage8_k2_wacb_run_guarded' -and
        [string]$_.CommandLine -like "*$RepoDir*" -and
        [string]$_.CommandLine -like "*$RuntimeRoot*" -and
        [string]$_.CommandLine -like '*-singleCompThread*'
    })
    if ($state.state -ne 'TRIALS_RUNNING' -or $processes.Count -ne 1 -or
            $task.Settings.MultipleInstances -ne 'IgnoreNew' -or
            -not [bool]$task.Settings.StartWhenAvailable) {
        throw 'Immediate Tick, exact MATLAB identity, or task settings failed.'
    }
    return [pscustomobject]@{
        status = 'SCHEDULED_CONTROLLER_INSTALLED_AND_STARTED'
        task_name = $TaskName
        task_interval_minutes = $IntervalMinutes
        controller_state = $state.state
        active_matlab_pid = $state.active_matlab_pid
        exact_matlab_process_count = $processes.Count
        no_interactive_codex_polling = $true
    }
}

function Invoke-Status {
    Ensure-ControllerDirectory
    $state = Read-JsonFile $script:StatePath
    $snapshot = Get-BoundedSnapshot $state
    return [pscustomobject]@{
        protocol = $state.protocol
        state = $state.state
        completed = $snapshot.completed
        total = 1680
        remaining = 1680 - [int]$snapshot.completed
        active_matlab_pid = if ($snapshot.matching_processes.Count -eq 1) {
            $snapshot.matching_processes[0].ProcessId
        } else { 0 }
        active_matlab_role = if ($snapshot.matching_processes.Count -eq 1) {
            $snapshot.matching_processes[0].Role
        } else { 'NONE' }
        last_error = $state.last_error
        next = $state.next_automatic_action
        last_tick_utc = $state.last_tick_utc
    }
}

switch ($Action) {
    'InstallAndStart' { Invoke-InstallAndStart }
    'RecoverFalseDuplicateHardStop' { Invoke-RecoverFalseDuplicateHardStop }
    'Tick' { Invoke-Tick }
    'Status' { Invoke-Status }
    'Uninstall' {
        Remove-ProtocolTask | Out-Null
        [pscustomobject]@{ status = 'SCHEDULED_CONTROLLER_UNREGISTERED' }
    }
}
