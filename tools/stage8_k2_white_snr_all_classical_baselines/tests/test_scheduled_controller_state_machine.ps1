[CmdletBinding()]
param(
    [string]$RepoDir = 'E:\bs_innovation',
    [string]$AttestationRuntime = ''
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$controller = Join-Path $RepoDir `
    'tools\stage8_k2_white_snr_all_classical_baselines\powershell\Stage8K2WACBController.ps1'
$closeout = Join-Path $RepoDir `
    'tools\stage8_k2_white_snr_all_classical_baselines\powershell\Stage8K2WACBCloseout.ps1'
$matlab = 'E:\MATLABR2022b\bin\matlab.exe'
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ("stage8_k2_wacb_controller_test_{0}_{1}" -f $PID, [Guid]::NewGuid().ToString('N'))
$runtime = Join-Path $testRoot 'runtime'
$controllerDir = Join-Path $runtime 'controller'
$snapshotPath = Join-Path $testRoot 'snapshot.json'
$pathsPath = Join-Path $testRoot 'allowed_paths.txt'
$taskName = "BSInnovation-Stage8K2-WACB-V2-TEST-$PID"
$registered = $false

function Write-Json {
    param([string]$Path, [object]$Value)
    $json = $Value | ConvertTo-Json -Depth 16
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, $utf8)
}

function Read-State {
    return Get-Content -LiteralPath (Join-Path $controllerDir `
        'controller_state.json') -Raw | ConvertFrom-Json
}

function Write-Snapshot {
    param(
        [int]$Completed = 0,
        [bool]$Ready = $false,
        [object[]]$Processes = @(),
        [object]$Manifest = $null,
        [string]$CloseoutResult = ''
    )
    Write-Json $snapshotPath ([ordered]@{
        processes = @($Processes)
        completed_checkpoints = $Completed
        tmp_count = 0
        ready = $Ready
        hard_stop = $false
        latest_status = $null
        manifest = $Manifest
        closeout_result = $CloseoutResult
    })
}

function Invoke-TestTick {
    return & $controller -Action Tick -RepoDir $RepoDir -RuntimeRoot $runtime `
        -MatlabExe $matlab -TaskName $taskName -IntervalMinutes 15 `
        -TestMode -SnapshotPath $snapshotPath
}

function Get-MutexName {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(
            ([System.IO.Path]::GetFullPath($runtime).ToLowerInvariant()))
        $digest = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '')
    } finally { $sha.Dispose() }
    return "Local\BSInnovationStage8K2WACB_$($digest.Substring(0, 24))"
}

try {
    New-Item -ItemType Directory -Path $controllerDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $runtime 'logs') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $runtime 'checkpoints') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $runtime 'status') -Force | Out-Null

    $source = Get-Content -LiteralPath $controller -Raw
    $tickFunction = [regex]::Match($source,
        '(?s)function Get-BoundedSnapshot\s*\{.*?\n\}').Value
    if ($source -match '\bStart-Sleep\b' -or $source -match '(?m)^\s*while\s*\(' -or
            $source -match '(?m)^\s*do\s*\{' -or
            ([regex]::Matches($tickFunction, 'Get-CimInstance\s+Win32_Process')).Count -ne 1) {
        throw 'Tick source contains polling/sleep or more than one process snapshot.'
    }

    $taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument '-NoProfile -Command "exit 0"'
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15) `
        -RepetitionInterval (New-TimeSpan -Minutes 15)
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $principal = New-ScheduledTaskPrincipal -UserId $identity `
        -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $taskName -Action $taskAction `
        -Trigger $trigger -Settings $settings -Principal $principal `
        -Description 'Temporary Stage8 K2 WACB controller contract test.' | Out-Null
    $registered = $true
    $task = Get-ScheduledTask -TaskName $taskName
    $interval = [string]@($task.Triggers)[0].Repetition.Interval
    if ($interval -ne 'PT15M' -or
            [string]$task.Settings.MultipleInstances -ne 'IgnoreNew' -or
            -not [bool]$task.Settings.StartWhenAvailable) {
        throw 'Temporary task interval or settings differ from the contract.'
    }

    $now = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $state = [ordered]@{
        protocol = 'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_V2'
        branch = 'work/stage8-k2-white-snr-all-classical-baselines-v1'
        formal_head = 'TEST'; code_identity = 'TEST'; registry_hash = 'TEST'
        evidence44_identity = 'TEST'; evidence46_identity = 'TEST'
        state = 'PREPARED'; last_transition_utc = $now; last_tick_utc = $now
        task_name = $taskName; task_interval_minutes = 15
        trial_launch_count = 0; resume_launch_count = 0
        finalization_launch_count = 0; audit_launch_count = 0
        git_closeout_attempt_count = 0; active_matlab_pid = 0
        active_matlab_role = 'NONE'; completed_checkpoints = 0
        remaining_checkpoints = 1680; median_trial_runtime_sec = $null
        ETA_sec = $null; last_valid_checkpoint = ''
        element_music_valid_count = 0; element_music_single_peak_count = 0
        element_music_na_count = 0; gfbss_elevation_valid_count = 0
        gfbss_end_to_end_valid_count = 0; root_elevation_valid_count = 0
        root_end_to_end_valid_count = 0; esprit_elevation_valid_count = 0
        esprit_end_to_end_valid_count = 0; conditional_az_cml_valid_count = 0
        last_error = ''; hard_stop_reason = ''; result_commit = ''
        push_status = 'NOT_STARTED'; next_automatic_action = 'START_TRIAL_RUNNER'
    }
    Write-Json (Join-Path $controllerDir 'controller_state.json') $state
    Write-Snapshot

    $mutex = New-Object System.Threading.Mutex($true, (Get-MutexName))
    try {
        $stdout = Join-Path $testRoot 'mutex_child.out'
        $stderr = Join-Path $testRoot 'mutex_child.err'
        $childArguments = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" ' +
            '-Action Tick -RepoDir "{1}" -RuntimeRoot "{2}" ' +
            '-MatlabExe "{3}" -TaskName "{4}" -IntervalMinutes 15 ' +
            '-TestMode -SnapshotPath "{5}"') -f $controller, $RepoDir,
            $runtime, $matlab, $taskName, $snapshotPath
        $child = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList $childArguments `
            -WindowStyle Hidden -RedirectStandardOutput $stdout `
            -RedirectStandardError $stderr -PassThru
        Wait-Process -Id $child.Id -Timeout 30
        $mutexOutput = Get-Content -LiteralPath $stdout -Raw
        if ($mutexOutput -notmatch 'TICK_SKIPPED_MUTEX_BUSY') {
            throw 'Named mutex did not reject a reentrant Tick.'
        }
    } finally {
        $mutex.ReleaseMutex(); $mutex.Dispose()
    }

    Invoke-TestTick | Out-Null
    $state = Read-State
    if ($state.state -ne 'TRIALS_RUNNING' -or [int]$state.trial_launch_count -ne 1) {
        throw 'PREPARED to TRIALS_RUNNING transition failed.'
    }
    $parentChildSession = @(
        [pscustomobject]@{ ProcessId = 9100; ParentProcessId = 1; Role = 'RUN' },
        [pscustomobject]@{ ProcessId = 9101; ParentProcessId = 9100; Role = 'RUN' })
    Write-Snapshot -Completed 5 -Processes $parentChildSession
    Invoke-TestTick | Out-Null
    $state = Read-State
    if ($state.state -ne 'TRIALS_RUNNING' -or
            [int]$state.active_matlab_pid -ne 9100 -or
            [int]$state.resume_launch_count -ne 0) {
        throw 'MATLAB launcher and child were not collapsed to one logical runner.'
    }
    Write-Snapshot -Completed 10
    Invoke-TestTick | Out-Null
    $state = Read-State
    if ($state.state -ne 'TRIALS_RUNNING' -or [int]$state.resume_launch_count -ne 1) {
        throw 'Incomplete checkpoint resume launch failed.'
    }
    Write-Snapshot -Completed 1680 -Ready $true
    Invoke-TestTick | Out-Null
    if ((Read-State).state -ne 'READY_TO_FINALIZE') {
        throw 'TRIALS_RUNNING to READY_TO_FINALIZE failed.'
    }
    Invoke-TestTick | Out-Null
    $state = Read-State
    if ($state.state -ne 'FINALIZATION_RUNNING' -or
            [int]$state.finalization_launch_count -ne 1) {
        throw 'Fresh finalization launch failed.'
    }
    $pendingManifest = [pscustomobject]@{
        status = 'FINALIZED_AWAITING_INDEPENDENT_AUDIT'
    }
    Write-Snapshot -Completed 1680 -Ready $true -Manifest $pendingManifest
    Invoke-TestTick | Out-Null
    if ((Read-State).state -ne 'READY_FOR_AUDIT') {
        throw 'Finalization completion transition failed.'
    }
    Invoke-TestTick | Out-Null
    $state = Read-State
    if ($state.state -ne 'AUDIT_RUNNING' -or [int]$state.audit_launch_count -ne 1) {
        throw 'Fresh audit launch failed.'
    }
    $passManifest = [pscustomobject]@{
        status = 'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE'
        independent_audit_status = 'PASS'; checkpoint_count = 1680
        new_method_row_count = 6720; diagnostic_row_count = 6720
        all_method_row_count = 16800; representative_spectra_count = 56
        existing_method_rerun_count = 0
    }
    Write-Snapshot -Completed 1680 -Ready $true -Manifest $passManifest
    Invoke-TestTick | Out-Null
    if ((Read-State).state -ne 'READY_FOR_GIT_CLOSEOUT') {
        throw 'Audit PASS to READY_FOR_GIT_CLOSEOUT failed.'
    }
    Write-Snapshot -Completed 1680 -Ready $true -Manifest $passManifest `
        -CloseoutResult 'COMPLETE'
    Invoke-TestTick | Out-Null
    $state = Read-State
    if ($state.state -ne 'COMPLETE' -or
            $null -ne (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
        throw 'COMPLETE transition or task self-unregistration failed.'
    }
    $registered = $false
    $before = [int]$state.git_closeout_attempt_count
    Invoke-TestTick | Out-Null
    $after = [int](Read-State).git_closeout_attempt_count
    if ($before -ne $after) { throw 'Repeated COMPLETE Tick is not idempotent.' }

    $state = Read-State
    $state.state = 'TRIALS_RUNNING'
    $state.last_error = ''
    $state.hard_stop_reason = ''
    $state.next_automatic_action = 'OBSERVE_OR_RESUME_TRIALS'
    $launches = [int]$state.trial_launch_count + [int]$state.resume_launch_count +
        [int]$state.finalization_launch_count + [int]$state.audit_launch_count
    Write-Json (Join-Path $controllerDir 'controller_state.json') $state
    $independentSessions = @(
        [pscustomobject]@{ ProcessId = 9200; ParentProcessId = 1; Role = 'RUN' },
        [pscustomobject]@{ ProcessId = 9300; ParentProcessId = 1; Role = 'RUN' })
    Write-Snapshot -Completed 100 -Processes $independentSessions
    Invoke-TestTick | Out-Null
    $state = Read-State
    $launchesAfter = [int]$state.trial_launch_count + [int]$state.resume_launch_count +
        [int]$state.finalization_launch_count + [int]$state.audit_launch_count
    if ($launches -ne $launchesAfter -or $state.state -ne 'HARD_STOPPED' -or
            $state.hard_stop_reason -ne
            'Multiple exact protocol MATLAB processes detected.') {
        throw 'Independent MATLAB sessions did not trigger the duplicate hard stop.'
    }
    Invoke-TestTick | Out-Null
    $launchesRepeated = [int](Read-State).trial_launch_count +
        [int](Read-State).resume_launch_count +
        [int](Read-State).finalization_launch_count +
        [int](Read-State).audit_launch_count
    if ($launchesAfter -ne $launchesRepeated) {
        throw 'HARD_STOPPED Tick launched work.'
    }

    $allowed = @(
        'innovation-mining/48_fixture.csv',
        'innovation-mining/figures/48_fixture.png',
        'innovation-mining/stage8_execution_prompts/active/README.md',
        'innovation-mining/00_DOCUMENT_STATUS_INDEX.md')
    [System.IO.File]::WriteAllLines($pathsPath, $allowed, $utf8)
    $scope = & $closeout -Action ValidatePaths -RepoDir $RepoDir `
        -RuntimeRoot $runtime -TaskName $taskName -PathsFile $pathsPath
    if ($scope.status -ne 'ALLOWED_PATH_AUDIT_PASS') {
        throw 'Closeout allowed-path dry-run failed.'
    }

    $result = [ordered]@{
        pass = $true
        status = 'STAGE8_K2_WACB_SCHEDULED_CONTROLLER_TEST_PASS'
        test_count = 1
        task_registration = 'PASS'
        interval_minutes = 15
        multiple_instances = 'IgnoreNew'
        start_when_available = $true
        mutex_reentry_blocked = $true
        matlab_parent_child_collapsed = $true
        independent_runner_duplicate_rejected = $true
        state_machine = 'PASS'
        allowed_path_audit = 'PASS'
        repeated_tick_idempotent = $true
        complete_task_unregistered = $true
        hard_stopped_no_launch = $true
        completed_utc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    }
    if (-not [string]::IsNullOrWhiteSpace($AttestationRuntime)) {
        $attestationDir = Join-Path $AttestationRuntime 'controller'
        New-Item -ItemType Directory -Path $attestationDir -Force | Out-Null
        Write-Json (Join-Path $attestationDir `
            'scheduled_controller_test_pass.json') $result
    }
    [pscustomobject]$result
} finally {
    if ($registered) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false `
            -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
