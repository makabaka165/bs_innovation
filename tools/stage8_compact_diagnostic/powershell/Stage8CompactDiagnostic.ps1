[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Pilot', 'Init', 'Start', 'Status', 'Pause', 'Resume',
        'Finalize', 'RegisterStatusTask', 'UnregisterStatusTask')]
    [string]$Action,

    [string]$RuntimeRoot =
        'E:\bs_innovation_runtime\stage8_compact_k1_k2_diagnostic_4worker_v2_237e351',

    [string]$RepoDir = 'E:\bs_innovation',

    [string]$MatlabExe = 'E:\MATLABR2022b\bin\matlab.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProtocolVersion = 'STAGE8_COMPACT_K1_K2_DIAGNOSTIC_4WORKER_V2'
$Authorization = 'AUTHORIZE_STAGE8_COMPACT_K1_K2_DIAGNOSTIC_4WORKER_V2'
$StatusTaskName = 'BSInnovation-Stage8Compact-Status'
$OldRuntimeRoot =
    'E:\bs_innovation_runtime\stage8_1b_k1_validation_sharded_resumable_v2_9bfa65e6'
$K1SmokeEvidence =
    'E:\bs_innovation_runtime\stage8_1b_sharded_implementation_tests\nonformal_scientific_smoke.log'
$ToolRoot = Split-Path -Parent $PSScriptRoot
$MatlabToolDir = Join-Path $ToolRoot 'matlab'
$StepRoot = Join-Path $RepoDir (
    'beamspace_ml_v18\source\stepwise_signal_model\steps\' +
    'step_12_6_k12_bootstrap_resolution')
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function ConvertTo-MatlabLiteral {
    param([string]$Value)
    return $Value.Replace("'", "''")
}

function Get-UtcNowText {
    return [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

function Write-JsonAtomic {
    param([string]$Path, [object]$Value)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $temporary = "$Path.tmp"
    $json = $Value | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($temporary,
        $json + [Environment]::NewLine, $script:Utf8NoBom)
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing JSON file: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Assert-Paths {
    foreach ($path in @($RepoDir, $MatlabToolDir, $StepRoot)) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            throw "Required directory not found: $path"
        }
    }
    if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {
        throw "MATLAB R2022b executable not found: $MatlabExe"
    }
}

function Get-ProcessAudit {
    $selfId = $PID
    $processes = @(Get-CimInstance Win32_Process)
    $matlab = @($processes | Where-Object { $_.Name -match '^MATLAB.*' })
    $mwpython = @($processes | Where-Object { $_.Name -match '^mwpython.*' })
    $coordinators = @($processes | Where-Object {
        $_.ProcessId -ne $selfId -and
        $_.CommandLine -match 'stage8.*coordinator|coordinator.*stage8'
    })
    $lockRoot =
        'E:\bs_innovation_runtime\stage8_1b_a5r2_cellwise_7dc1e4c3\locks'
    $locks = @(Get-ChildItem -LiteralPath $lockRoot -File `
        -ErrorAction SilentlyContinue)
    return [ordered]@{
        matlab_count = $matlab.Count
        mwpython_count = $mwpython.Count
        coordinator_count = $coordinators.Count
        active_lock_count = $locks.Count
        checked_utc = Get-UtcNowText
    }
}

function Assert-NoMatlabCoordinatorOrLock {
    $audit = Get-ProcessAudit
    if ($audit.matlab_count -ne 0 -or $audit.mwpython_count -ne 0 -or
            $audit.coordinator_count -ne 0 -or $audit.active_lock_count -ne 0) {
        throw ('MATLAB/mwpython/coordinator/active-lock preflight failed: ' +
            "$($audit.matlab_count)/$($audit.mwpython_count)/" +
            "$($audit.coordinator_count)/$($audit.active_lock_count)")
    }
    return $audit
}

function Assert-NoForeignStage8StatusTask {
    $tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -like 'BSInnovation-Stage8*' })
    $foreign = @($tasks | Where-Object { $_.TaskName -ne $StatusTaskName })
    if ($foreign.Count -ne 0) {
        throw "A foreign Stage8 scheduled task is registered: $($foreign.TaskName -join ', ')"
    }
}

function Invoke-MatlabBatch {
    param([string]$Expression, [string]$LogPath)
    $parent = Split-Path -Parent $LogPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    & $MatlabExe -singleCompThread -logfile $LogPath -batch $Expression
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB batch failed with exit code $LASTEXITCODE. Log: $LogPath"
    }
}

function Start-MatlabExpression {
    param([string]$Expression, [string]$LogPath)
    $parent = Split-Path -Parent $LogPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $MatlabExe
    $startInfo.Arguments =
        "-singleCompThread -logfile `"$LogPath`" -batch `"$Expression`""
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw "Unable to start MATLAB process for $LogPath"
    }
    return $process
}

function Start-Worker {
    param([string]$Root, [int]$WorkerId, [string]$Label)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');" +
        "stage8_compact_worker('$repo','$runtime',$WorkerId);"
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $logPath = Join-Path $Root (
        "logs\worker_$('{0:D2}' -f $WorkerId)_${Label}_$stamp.log")
    $process = Start-MatlabExpression $expression $logPath
    $pidPath = Join-Path $Root "workers\worker_$('{0:D2}' -f $WorkerId).pid"
    [System.IO.File]::WriteAllText($pidPath, "$($process.Id)`n", $Utf8NoBom)
    return $process
}

function Get-MatchingWorkerProcesses {
    param([string]$Root)
    return @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^MATLAB.*' -and
        $_.ExecutablePath -like '*\bin\win64\MATLAB.exe' -and
        $_.CommandLine -like "*$Root*" -and
        $_.CommandLine -match 'stage8_compact_worker'
    })
}

function Get-SystemMemorySample {
    $os = Get-CimInstance Win32_OperatingSystem
    $total = [double]$os.TotalVisibleMemorySize * 1024
    $available = [double]$os.FreePhysicalMemory * 1024
    $utilization = if ($total -gt 0) {
        ($total - $available) / $total
    } else { 1.0 }
    $pages = 0.0
    try {
        $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
        $pages = [double]$memory.PagesInputPerSec
    } catch { $pages = 0.0 }
    return [pscustomobject]@{
        TotalBytes = $total
        AvailableBytes = $available
        Utilization = $utilization
        PagesInputPerSec = $pages
    }
}

function Wait-WorkerProcesses {
    param(
        [System.Diagnostics.Process[]]$Processes,
        [string]$Root,
        [int]$PauseAfterCheckpointCount = -1
    )
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $peakUtilization = 0.0
    $minimumAvailable = [double]::PositiveInfinity
    $pageSamples = New-Object System.Collections.Generic.List[double]
    $pauseCreated = $false
    while ($true) {
        $active = 0
        foreach ($process in $Processes) {
            $process.Refresh()
            if (-not $process.HasExited) { $active++ }
        }
        $sample = Get-SystemMemorySample
        $peakUtilization = [Math]::Max($peakUtilization, $sample.Utilization)
        $minimumAvailable = [Math]::Min($minimumAvailable,
            $sample.AvailableBytes)
        $pageSamples.Add($sample.PagesInputPerSec)
        if ($PauseAfterCheckpointCount -ge 0 -and -not $pauseCreated) {
            $completed = @(Get-ChildItem -LiteralPath `
                (Join-Path $Root 'checkpoints') -Filter '*.mat' -File `
                -ErrorAction SilentlyContinue).Count
            if ($completed -ge $PauseAfterCheckpointCount) {
                $request = Join-Path $Root 'control\pause.request'
                [System.IO.File]::WriteAllText($request,
                    "requested_utc=$(Get-UtcNowText)`nrequested_by=GATE_C3`n",
                    $Utf8NoBom)
                $pauseCreated = $true
            }
        }
        if ($active -eq 0) { break }
        Start-Sleep -Milliseconds 1000
    }
    $stopwatch.Stop()
    $exitCodes = @()
    foreach ($process in $Processes) {
        $process.WaitForExit()
        $exitCodes += $process.ExitCode
        $process.Dispose()
    }
    $highPages = @($pageSamples | Where-Object { $_ -ge 1000 }).Count
    $thrashing = $pageSamples.Count -ge 5 -and
        $highPages -ge [Math]::Ceiling($pageSamples.Count / 2.0)
    return [pscustomobject]@{
        WallSec = $stopwatch.Elapsed.TotalSeconds
        PeakTotalMemoryUtilization = $peakUtilization
        MinimumAvailablePhysicalBytes = $minimumAvailable
        SustainedPagefileThrashing = $thrashing
        ExitCodes = $exitCodes
        PauseCreated = $pauseCreated
    }
}

function Initialize-ProtocolRoot {
    param(
        [string]$Root,
        [int]$WorkerCount,
        [int[]]$TrialIndices,
        [string]$Mode,
        [string]$Role,
        [int]$GraceSeconds = 0,
        [string]$DecisionPath = ''
    )
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $modeValue = ConvertTo-MatlabLiteral $Mode
    $roleValue = ConvertTo-MatlabLiteral $Role
    $indices = '[' + (($TrialIndices | ForEach-Object { [string]$_ }) -join ' ') + ']'
    if ($DecisionPath -eq '') {
        $options = "struct('protocol_role','$roleValue'," +
            "'inter_trial_grace_sec',$GraceSeconds)"
    } else {
        $decision = ConvertTo-MatlabLiteral $DecisionPath
        $options = "struct('protocol_role','$roleValue'," +
            "'inter_trial_grace_sec',$GraceSeconds," +
            "'require_gate_decision',true,'gate_decision_path','$decision')"
    }
    $expression = "addpath('$tool');" +
        "stage8_compact_initialize_runtime('$repo','$runtime',$WorkerCount," +
        "$indices,'$modeValue',$options);"
    Invoke-MatlabBatch $expression (Join-Path $Root 'logs\initialize.log')
}

function Invoke-RuntimeAudit {
    param([string]$Root, [string]$Label)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');" +
        "s=stage8_compact_build_status('$repo','$runtime');" +
        "assert(s.invalid_checkpoint_count==0);" +
        "assert(s.unexpected_checkpoint_count==0);" +
        "assert(s.tmp_checkpoint_count==0);assert(s.current_trial_lock_count==0);"
    Invoke-MatlabBatch $expression (Join-Path $Root "logs\${Label}.log")
}

function Archive-PauseRequest {
    param([string]$Root, [string]$Label)
    $path = Join-Path $Root 'control\pause.request'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
    $archive = Join-Path $Root 'control\archive'
    if (-not (Test-Path -LiteralPath $archive -PathType Container)) {
        New-Item -ItemType Directory -Path $archive -Force | Out-Null
    }
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    Move-Item -LiteralPath $path -Destination `
        (Join-Path $archive "pause_${Label}_$stamp.request")
}

function Archive-StaleRuntimeWrites {
    param([string]$Root)
    if ((Get-MatchingWorkerProcesses $Root).Count -ne 0) {
        throw 'Cannot archive stale writes while compact workers are active.'
    }
    $incomplete = Join-Path $Root 'incomplete'
    if (-not (Test-Path -LiteralPath $incomplete -PathType Container)) {
        New-Item -ItemType Directory -Path $incomplete -Force | Out-Null
    }
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    foreach ($item in @(Get-ChildItem -LiteralPath (Join-Path $Root 'tmp') `
            -Filter '*.tmp' -File -ErrorAction SilentlyContinue)) {
        Move-Item -LiteralPath $item.FullName -Destination `
            (Join-Path $incomplete "$($item.Name).resume_$stamp")
    }
    foreach ($item in @(Get-ChildItem -LiteralPath (Join-Path $Root 'workers') `
            -Filter '*.current.lock' -File -ErrorAction SilentlyContinue)) {
        Move-Item -LiteralPath $item.FullName -Destination `
            (Join-Path $incomplete "$($item.Name).resume_$stamp")
    }
}

function Test-SafePause {
    param([string]$Root, [int]$WorkerCount)
    if ((Get-MatchingWorkerProcesses $Root).Count -ne 0) { return $false }
    if (@(Get-ChildItem -LiteralPath (Join-Path $Root 'tmp') -Filter '*.tmp' `
            -File -ErrorAction SilentlyContinue).Count -ne 0) { return $false }
    if (@(Get-ChildItem -LiteralPath (Join-Path $Root 'workers') `
            -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count -ne 0) {
        return $false
    }
    for ($workerId = 1; $workerId -le $WorkerCount; $workerId++) {
        $path = Join-Path $Root `
            "workers\worker_$('{0:D2}' -f $workerId)_status.json"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
        if ([string](Read-JsonFile $path).worker_state -ne 'PAUSED_SAFE') {
            return $false
        }
    }
    return $true
}

function Get-CheckpointIdentity {
    param([string]$Root)
    return @(Get-ChildItem -LiteralPath (Join-Path $Root 'checkpoints') `
        -Filter '*.mat' -File | Sort-Object Name | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                Length = $_.Length
                LastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('o')
                SHA256 = (Get-FileHash -Algorithm SHA256 `
                    -LiteralPath $_.FullName).Hash
            }
        })
}

function Test-CheckpointIdentityUnchanged {
    param([object[]]$Before, [string]$Root)
    $after = Get-CheckpointIdentity $Root
    foreach ($item in $Before) {
        $match = @($after | Where-Object { $_.Name -eq $item.Name })
        if ($match.Count -ne 1 -or $match[0].Length -ne $item.Length -or
                $match[0].LastWriteTimeUtc -ne $item.LastWriteTimeUtc -or
                $match[0].SHA256 -ne $item.SHA256) { return $false }
    }
    return $true
}

function Compare-ProtocolRoots {
    param(
        [string]$Left,
        [string]$Right,
        [string]$ResultPath,
        [string]$GateName
    )
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $leftValue = ConvertTo-MatlabLiteral $Left
    $rightValue = ConvertTo-MatlabLiteral $Right
    $resultValue = ConvertTo-MatlabLiteral $ResultPath
    $gateValue = ConvertTo-MatlabLiteral $GateName
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');" +
        "stage8_compact_compare_runtime_roots('$repo','$leftValue'," +
        "'$rightValue','$resultValue','$gateValue');"
    Invoke-MatlabBatch $expression "$ResultPath.log"
    return Read-JsonFile $ResultPath
}

function Start-WorkerSet {
    param([string]$Root, [int]$WorkerCount, [string]$Label)
    $started = @()
    for ($workerId = 1; $workerId -le $WorkerCount; $workerId++) {
        $started += Start-Worker $Root $workerId $Label
    }
    return $started
}

function Assert-WorkerSuccess {
    param([object]$Metrics, [string]$Label)
    if (@($Metrics.ExitCodes | Where-Object { $_ -ne 0 }).Count -ne 0) {
        throw "$Label worker process failed: $($Metrics.ExitCodes -join ',')"
    }
}

function Write-ScopeChangeRecord {
    if (-not (Test-Path -LiteralPath $OldRuntimeRoot -PathType Container)) {
        throw "Preserved old runtime is missing: $OldRuntimeRoot"
    }
    $path = Join-Path $OldRuntimeRoot `
        'scope_change_record_compact_diagnostic_v2.json'
    $required = [ordered]@{
        status = 'FULL_STAGE8_1B_K1_VALIDATION_DEFERRED_NOT_FAILED'
        old_protocol = 'STAGE8_1B_K1_VALIDATION_SHARDED_RESUMABLE_V2'
        old_gate0 = 'PASS'
        old_gate1 = 'INTERRUPTED_BY_SCOPE_CHANGE'
        old_gate2 = 'NOT_STARTED'
        formal_trials_started = $false
        formal_results_written = $false
        stage8_2_executed = $false
        old_runtime_preserved = $true
        next_protocol = $ProtocolVersion
    }
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $existing = Read-JsonFile $path
        foreach ($name in $required.Keys) {
            if ([string]$existing.$name -ne [string]$required[$name]) {
                throw "Existing scope-change record differs at $name"
            }
        }
    } else {
        Write-JsonAtomic $path $required
    }
}

function Invoke-GateC0 {
    param([string]$PilotRoot)
    $audit = Assert-NoMatlabCoordinatorOrLock
    $auditPath = Join-Path $PilotRoot 'gate_c0_process_preflight.json'
    Write-JsonAtomic $auditPath $audit
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $output = ConvertTo-MatlabLiteral $PilotRoot
    $auditValue = ConvertTo-MatlabLiteral $auditPath
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');" +
        "stage8_compact_gate_c0('$repo','$output','$auditValue');"
    Invoke-MatlabBatch $expression (Join-Path $PilotRoot 'gate_c0.log')
    $result = Read-JsonFile (Join-Path $PilotRoot 'gate_c0_result.json')
    if (-not [bool]$result.gate_c0_pass) { throw 'Gate C0 failed.' }
    return $result
}

function Invoke-GateC1 {
    param([string]$PilotRoot)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $evidence = ConvertTo-MatlabLiteral $K1SmokeEvidence
    $output = ConvertTo-MatlabLiteral $PilotRoot
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');" +
        "stage8_compact_gate_c1('$repo','$evidence','$output');"
    Invoke-MatlabBatch $expression (Join-Path $PilotRoot 'gate_c1.log')
    $result = Read-JsonFile (Join-Path $PilotRoot 'gate_c1_result.json')
    if (-not [bool]$result.gate_c1_pass) { throw 'Gate C1 failed.' }
    return $result
}

function Invoke-GateC2 {
    param([string]$PilotRoot)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $output = ConvertTo-MatlabLiteral $PilotRoot
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');" +
        "stage8_compact_gate_c2('$repo','$output');"
    Invoke-MatlabBatch $expression (Join-Path $PilotRoot 'gate_c2.log')
    $result = Read-JsonFile (Join-Path $PilotRoot 'gate_c2_result.json')
    if (-not [bool]$result.gate_c2_pass) { throw 'Gate C2 failed.' }
    return $result
}

function Invoke-GateC3 {
    param([string]$PilotRoot)
    $root = Join-Path $PilotRoot 'gate_c3'
    $reference = Join-Path $root 'single_uninterrupted'
    $resumed = Join-Path $root 'single_resumed'
    if (Test-Path -LiteralPath $root) {
        throw "Gate C3 root already exists and is preserved: $root"
    }
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $selection = @(1, 61)
    Initialize-ProtocolRoot $reference 1 $selection 'ONE_WORKER_REFERENCE' `
        'GATE_C3_REFERENCE' 0
    Initialize-ProtocolRoot $resumed 1 $selection 'ONE_WORKER_RESUME_TEST' `
        'GATE_C3_RESUMED' 5

    $referenceProcess = Start-Worker $reference 1 'uninterrupted'
    $referenceMetrics = Wait-WorkerProcesses @($referenceProcess) $reference
    Assert-WorkerSuccess $referenceMetrics 'Gate C3 uninterrupted'

    $beforePause = Start-Worker $resumed 1 'before_pause'
    $pauseMetrics = Wait-WorkerProcesses @($beforePause) $resumed 1
    Assert-WorkerSuccess $pauseMetrics 'Gate C3 before-pause'
    $pauseCount = @(Get-ChildItem -LiteralPath `
        (Join-Path $resumed 'checkpoints') -Filter '*.mat' -File).Count
    if (-not $pauseMetrics.PauseCreated -or $pauseCount -ne 1 -or
            -not (Test-SafePause $resumed 1)) {
        throw "Gate C3 did not reach the required safe pause (count=$pauseCount)."
    }
    $beforeIdentity = Get-CheckpointIdentity $resumed
    Archive-PauseRequest $resumed 'gate_c3_resume'
    Invoke-RuntimeAudit $resumed 'gate_c3_resume_preflight'
    $afterPause = Start-Worker $resumed 1 'after_resume'
    $resumeMetrics = Wait-WorkerProcesses @($afterPause) $resumed
    Assert-WorkerSuccess $resumeMetrics 'Gate C3 after-resume'
    $identityPass = Test-CheckpointIdentityUnchanged $beforeIdentity $resumed
    $comparisonPath = Join-Path $root 'gate_c3_comparison.json'
    $comparison = Compare-ProtocolRoots $reference $resumed $comparisonPath 'C3'
    $pass = [bool]$comparison.pass -and $identityPass
    $result = [ordered]@{
        gate_c3_pass = $pass
        status = if ($pass) { 'COMPACT_GATE_C3_RESUME_PASS' } else {
            'COMPACT_GATE_C3_RESUME_FAIL_STOPPED'
        }
        pause_created_after_first_trial = [bool]$pauseMetrics.PauseCreated
        safe_to_shutdown = $true
        active_worker_count = 0
        tmp_checkpoint_count = 0
        current_trial_lock_count = 0
        pre_resume_checkpoint_identity_pass = $identityPass
        new_matlab_session_resume_count = 1
        comparison = $comparison
        checked_utc = Get-UtcNowText
    }
    Write-JsonAtomic (Join-Path $root 'gate_c3_result.json') $result
    if (-not $pass) { throw 'Gate C3 checkpoint/resume equivalence failed.' }
    return [pscustomobject]$result
}

function Get-CandidateWorkerCount {
    $sample = Get-SystemMemorySample
    $availableGiB = $sample.AvailableBytes / 1GB
    $count = if ($availableGiB -ge 8.0) { 4 }
        elseif ($availableGiB -ge 6.0) { 3 }
        elseif ($availableGiB -ge 4.5) { 2 }
        else { 1 }
    return [pscustomobject]@{
        WorkerCount = $count
        AvailableBytes = $sample.AvailableBytes
        AvailableGiB = $availableGiB
        TotalBytes = $sample.TotalBytes
    }
}

function Invoke-GateC4 {
    param([string]$PilotRoot)
    $root = Join-Path $PilotRoot 'gate_c4'
    if (Test-Path -LiteralPath $root) {
        throw "Gate C4 root already exists and is preserved: $root"
    }
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $selection = @(1, 11, 21, 31, 41, 51, 61, 69, 77, 85, 93, 101)
    $reference = Join-Path $root 'single_reference'
    Initialize-ProtocolRoot $reference 1 $selection 'ONE_WORKER_REFERENCE' `
        'GATE_C4_REFERENCE' 0
    $referenceProcess = Start-Worker $reference 1 'reference'
    $referenceMetrics = Wait-WorkerProcesses @($referenceProcess) $reference
    Assert-WorkerSuccess $referenceMetrics 'Gate C4 reference'

    $memoryDecision = Get-CandidateWorkerCount
    $candidate = [int]$memoryDecision.WorkerCount
    $attempts = @()
    $selectedCount = 0
    $selectedMode = ''
    $fallbackReason = 'NONE'
    $selectedComparison = $null
    while ($candidate -ge 1) {
        $candidateRoot = Join-Path $root "candidate_${candidate}_worker"
        $mode = if ($candidate -eq 4) { 'FOUR_WORKER_CANDIDATE' }
            elseif ($candidate -eq 1) { 'ONE_WORKER_CANDIDATE' }
            else { 'N_WORKER_CANDIDATE' }
        Initialize-ProtocolRoot $candidateRoot $candidate $selection $mode `
            'GATE_C4_CANDIDATE' 0
        $processes = @(Start-WorkerSet $candidateRoot $candidate 'candidate')
        $metrics = Wait-WorkerProcesses $processes $candidateRoot
        $workerPass = @($metrics.ExitCodes | Where-Object { $_ -ne 0 }).Count -eq 0
        $comparisonPath = Join-Path $root `
            "gate_c4_comparison_${candidate}_worker.json"
        $comparison = if ($workerPass) {
            Compare-ProtocolRoots $reference $candidateRoot $comparisonPath 'C4'
        } else {
            [pscustomobject]@{ pass = $false; last_error = 'WORKER_EXIT_FAILURE' }
        }
        $sciencePass = $workerPass -and [bool]$comparison.pass
        $resourceReasons = @()
        if ($metrics.PeakTotalMemoryUtilization -gt 0.88) {
            $resourceReasons += 'MEMORY_UTILIZATION_ABOVE_88_PERCENT'
        }
        if ($metrics.MinimumAvailablePhysicalBytes -lt 2GB) {
            $resourceReasons += 'AVAILABLE_MEMORY_BELOW_2_GIB'
        }
        if ($metrics.SustainedPagefileThrashing) {
            $resourceReasons += 'SUSTAINED_PAGEFILE_THRASHING'
        }
        if ($metrics.WallSec -gt 1.20 * $referenceMetrics.WallSec) {
            $resourceReasons += 'CANDIDATE_MORE_THAN_20_PERCENT_SLOWER'
        }
        if (-not $workerPass) { $resourceReasons += 'WORKER_ABNORMAL_EXIT' }
        $resourcePass = $resourceReasons.Count -eq 0
        $attempt = [pscustomobject]@{
            candidate_worker_count = $candidate
            candidate_root = $candidateRoot
            scientific_equivalence_pass = $sciencePass
            resource_gate_pass = $resourcePass
            candidate_wall_sec = $metrics.WallSec
            single_worker_wall_sec = $referenceMetrics.WallSec
            peak_total_memory_utilization = $metrics.PeakTotalMemoryUtilization
            minimum_available_physical_bytes =
                $metrics.MinimumAvailablePhysicalBytes
            sustained_pagefile_thrashing =
                $metrics.SustainedPagefileThrashing
            resource_failure_reasons = @($resourceReasons)
        }
        $attempts += $attempt
        Write-JsonAtomic (Join-Path $candidateRoot 'resource_gate.json') $attempt
        if (-not $sciencePass) {
            $selectedCount = 1
            $selectedMode = 'ONE_WORKER_RESUMABLE'
            $fallbackReason = "SCIENTIFIC_MISMATCH_AT_${candidate}_WORKERS"
            $selectedComparison = $comparison
            break
        }
        if ($resourcePass) {
            $selectedCount = $candidate
            $selectedMode = if ($candidate -eq 4) {
                'FOUR_WORKER_RESUMABLE'
            } elseif ($candidate -eq 1) {
                'ONE_WORKER_RESUMABLE'
            } else { 'N_WORKER_RESUMABLE' }
            $fallbackReason = if ($candidate -eq $memoryDecision.WorkerCount) {
                'NONE'
            } else { 'RESOURCE_GATE_DOWNGRADE' }
            $selectedComparison = $comparison
            break
        }
        $candidate--
    }
    if ($selectedCount -eq 0) {
        throw 'Gate C4 could not select a resource-safe execution mode.'
    }
    $pass = $selectedCount -eq 1 -or [bool]$selectedComparison.pass
    $result = [ordered]@{
        gate_c4_pass = $pass
        status = if ($pass) { 'COMPACT_GATE_C4_EQUIVALENCE_PASS' } else {
            'COMPACT_GATE_C4_FAIL_STOPPED'
        }
        startup_available_physical_bytes = $memoryDecision.AvailableBytes
        startup_available_physical_gib = $memoryDecision.AvailableGiB
        initial_candidate_worker_count = $memoryDecision.WorkerCount
        selected_worker_count = $selectedCount
        selected_execution_mode = $selectedMode
        fallback_reason = $fallbackReason
        attempts = @($attempts)
        checked_utc = Get-UtcNowText
    }
    Write-JsonAtomic (Join-Path $root 'gate_c4_result.json') $result
    if (-not $pass) { throw 'Gate C4 failed to produce a valid execution mode.' }
    return [pscustomobject]$result
}

function Invoke-Pilot {
    Assert-NoForeignStage8StatusTask
    $audit = Assert-NoMatlabCoordinatorOrLock
    $existingTask = Get-ScheduledTask -TaskName $StatusTaskName `
        -ErrorAction SilentlyContinue
    if ($null -ne $existingTask) {
        throw 'The compact status task must not be registered before Pilot.'
    }
    Write-ScopeChangeRecord
    if (-not (Test-Path -LiteralPath $RuntimeRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null
    }
    $pilotRoot = Join-Path $RuntimeRoot 'pilot'
    $decisionPath = Join-Path $pilotRoot 'pilot_decision.json'
    if (Test-Path -LiteralPath $decisionPath -PathType Leaf) {
        return Read-JsonFile $decisionPath
    }
    if (Test-Path -LiteralPath $pilotRoot -PathType Container) {
        if (@(Get-ChildItem -LiteralPath $pilotRoot -Force).Count -ne 0) {
            throw "Incomplete Pilot is preserved and will not be overwritten: $pilotRoot"
        }
    } else {
        New-Item -ItemType Directory -Path $pilotRoot -Force | Out-Null
    }
    Write-JsonAtomic (Join-Path $pilotRoot 'pilot_start_audit.json') $audit
    $c0 = Invoke-GateC0 $pilotRoot
    $c1 = Invoke-GateC1 $pilotRoot
    $c2 = Invoke-GateC2 $pilotRoot
    $c3 = Invoke-GateC3 $pilotRoot
    $c4 = Invoke-GateC4 $pilotRoot
    $decision = [ordered]@{
        protocol_version = $ProtocolVersion
        execution_authorization = $Authorization
        gate_c0_pass = [bool]$c0.gate_c0_pass
        gate_c1_pass = [bool]$c1.gate_c1_pass
        gate_c2_pass = [bool]$c2.gate_c2_pass
        gate_c3_pass = [bool]$c3.gate_c3_pass
        gate_c4_pass = [bool]$c4.gate_c4_pass
        gate_c0_status = [string]$c0.status
        gate_c1_status = [string]$c1.status
        gate_c2_status = [string]$c2.status
        gate_c3_status = [string]$c3.status
        gate_c4_status = [string]$c4.status
        protocol_runner_commit = [string]$c0.protocol_runner_commit
        diagnostic_protocol_source_hash =
            [string]$c0.diagnostic_protocol_source_hash
        selected_worker_count = [int]$c4.selected_worker_count
        selected_execution_mode = [string]$c4.selected_execution_mode
        fallback_reason = [string]$c4.fallback_reason
        formal_6000_trial_status =
            'FULL_STAGE8_1B_K1_VALIDATION_DEFERRED_NOT_FAILED'
        stage8_2_executed_flag = $false
        decided_utc = Get-UtcNowText
    }
    Write-JsonAtomic $decisionPath $decision
    return [pscustomobject]$decision
}

function Get-Protocol {
    param([string]$Root = $RuntimeRoot)
    $protocol = Read-JsonFile (Join-Path $Root 'protocol.json')
    if ([string]$protocol.protocol_version -ne $ProtocolVersion -or
            [string]$protocol.execution_authorization -ne $Authorization -or
            [bool]$protocol.stage8_2_executed_flag -or
            [bool]$protocol.stage8_2_authorized_flag) {
        throw 'Runtime protocol version, authorization, or Stage8.2 boundary is invalid.'
    }
    return $protocol
}

function Get-Percentile {
    param([double[]]$Values, [double]$Probability)
    if ($null -eq $Values -or $Values.Count -eq 0) { return $null }
    $sorted = @($Values | Sort-Object)
    $position = ($sorted.Count - 1) * $Probability
    $left = [Math]::Floor($position)
    $right = [Math]::Ceiling($position)
    if ($left -eq $right) { return [double]$sorted[$left] }
    return [double]$sorted[$left] + ($position - $left) *
        ([double]$sorted[$right] - [double]$sorted[$left])
}

function Get-ClassStatistics {
    param([object[]]$Histories)
    $classes = @('K1_NO_SEPARATION', 'K1_SEPARATION_TRIGGERED',
        'K2_NON_SENTINEL', 'K2_SENTINEL_NO_SEPARATION',
        'K2_SENTINEL_SEPARATION_TRIGGERED')
    $result = [ordered]@{}
    foreach ($class in $classes) {
        $values = @($Histories | Where-Object {
            [string]$_.runtime_class -eq $class
        } | ForEach-Object { [double]$_.runtime_sec })
        $mean = if ($values.Count -eq 0) { $null } else {
            [double](($values | Measure-Object -Average).Average)
        }
        $result[$class] = [ordered]@{
            count = $values.Count
            p50_sec = Get-Percentile $values 0.50
            mean_sec = $mean
            p90_sec = Get-Percentile $values 0.90
        }
    }
    return $result
}

function Get-EtaEstimate {
    param(
        [object]$RegistryRow,
        [object[]]$Histories,
        [object]$ClassStatistics
    )
    $trialType = [string]$RegistryRow.trial_type
    $sentinel = [string]$RegistryRow.sentinel_flag -match '^(True|1)$'
    if ($trialType -eq 'K2' -and -not $sentinel) {
        $family = @('K2_NON_SENTINEL')
    } elseif ($trialType -eq 'K2') {
        $family = @('K2_SENTINEL_NO_SEPARATION',
            'K2_SENTINEL_SEPARATION_TRIGGERED')
    } else {
        $family = @('K1_NO_SEPARATION', 'K1_SEPARATION_TRIGGERED')
    }
    $values = @($Histories | Where-Object {
        $family -contains [string]$_.runtime_class
    } | ForEach-Object { [double]$_.runtime_sec })
    if ($values.Count -eq 0) {
        $values = @($Histories | ForEach-Object { [double]$_.runtime_sec })
    }
    if ($values.Count -eq 0) {
        return [pscustomobject]@{ Low = 0.0; Point = 0.0; High = 0.0 }
    }
    return [pscustomobject]@{
        Low = [double](Get-Percentile $values 0.50)
        Point = [double](($values | Measure-Object -Average).Average)
        High = [double](Get-Percentile $values 0.90)
    }
}

function Get-StatusSnapshot {
    $protocol = Get-Protocol
    $registry = @(Import-Csv -LiteralPath (Join-Path $RuntimeRoot 'registry.csv'))
    $checkpointFiles = @(Get-ChildItem -LiteralPath `
        (Join-Path $RuntimeRoot 'checkpoints') -Filter '*.mat' -File `
        -ErrorAction SilentlyContinue)
    $registryById = @{}
    foreach ($row in $registry) {
        $registryById[[string]$row.diagnostic_trial_id] = $row
    }
    $completedIds = New-Object System.Collections.Generic.HashSet[string]
    $invalidCount = 0
    foreach ($file in $checkpointFiles) {
        $id = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        if ($registryById.ContainsKey($id)) {
            [void]$completedIds.Add($id)
        } else { $invalidCount++ }
    }
    $completedRows = 0
    foreach ($id in $completedIds) {
        $completedRows += [int]$registryById[$id].expected_row_count
    }
    $historiesRaw = @()
    foreach ($path in @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'logs') `
            -Filter 'worker_*_checkpoint_history.csv' -File `
            -ErrorAction SilentlyContinue)) {
        $historiesRaw += @(Import-Csv -LiteralPath $path.FullName)
    }
    $histories = @($historiesRaw | Group-Object diagnostic_trial_id |
        ForEach-Object {
            $_.Group | Sort-Object created_utc | Select-Object -Last 1
        })
    $activeProcesses = @(Get-MatchingWorkerProcesses $RuntimeRoot)
    $workerViews = @()
    $lastError = ''
    for ($workerId = 1; $workerId -le [int]$protocol.selected_worker_count;
            $workerId++) {
        $statusPath = Join-Path $RuntimeRoot `
            "workers\worker_$('{0:D2}' -f $workerId)_status.json"
        $workerStatus = $null
        if (Test-Path -LiteralPath $statusPath -PathType Leaf) {
            try { $workerStatus = Read-JsonFile $statusPath } catch { }
        }
        $process = @($activeProcesses | Where-Object {
            $_.CommandLine -match "stage8_compact_worker.*,$workerId\)"
        } | Select-Object -First 1)
        $active = $process.Count -eq 1
        $current = if ($null -eq $workerStatus) { '' } else {
            [string]$workerStatus.current_trial_id
        }
        $started = if ($null -eq $workerStatus) { '' } else {
            [string]$workerStatus.current_trial_started_utc
        }
        $elapsed = 0.0
        if ($active -and $started -ne '') {
            try {
                $elapsed = ([DateTimeOffset]::UtcNow -
                    [DateTimeOffset]::Parse($started)).TotalSeconds
            } catch { $elapsed = 0.0 }
        }
        $state = if ($null -eq $workerStatus) { 'NOT_STARTED' } else {
            [string]$workerStatus.worker_state
        }
        $pidValue = if ($active) { [int]$process[0].ProcessId }
            elseif ($null -ne $workerStatus) { [int]$workerStatus.pid }
            else { 0 }
        if ($null -ne $workerStatus -and
                [string]$workerStatus.last_error -ne '' -and $lastError -eq '') {
            $lastError = [string]$workerStatus.last_error
        }
        $workerViews += [pscustomobject]@{
            worker_id = $workerId
            pid = $pidValue
            active = $active
            worker_state = $state
            current_trial = $current
            current_trial_elapsed_sec = $elapsed
            heartbeat_utc = if ($null -eq $workerStatus) { '' } else {
                [string]$workerStatus.heartbeat_utc
            }
        }
    }
    $perStratum = [ordered]@{}
    $perProfile = [ordered]@{}
    foreach ($row in $registry) {
        $stratum = [string]$row.stratum_id
        if (-not $perStratum.Contains($stratum)) {
            $perStratum[$stratum] = [ordered]@{ completed = 0; total = 0 }
        }
        $perStratum[$stratum].total++
        if ($completedIds.Contains([string]$row.diagnostic_trial_id)) {
            $perStratum[$stratum].completed++
        }
        if ([string]$row.trial_type -eq 'K2') {
            $profile = "${stratum}_P$('{0:D2}' -f [int]$row.profile_id)"
            if (-not $perProfile.Contains($profile)) {
                $perProfile[$profile] = [ordered]@{ completed = 0; total = 0 }
            }
            $perProfile[$profile].total++
            if ($completedIds.Contains([string]$row.diagnostic_trial_id)) {
                $perProfile[$profile].completed++
            }
        }
    }
    $k1Completed = @($registry | Where-Object {
        $_.trial_type -eq 'K1' -and $completedIds.Contains($_.diagnostic_trial_id)
    }).Count
    $k2Completed = @($registry | Where-Object {
        $_.trial_type -eq 'K2' -and $completedIds.Contains($_.diagnostic_trial_id)
    }).Count
    $stateCountsK1 = [ordered]@{}
    $stateCountsK2 = [ordered]@{}
    $separationCount = 0
    foreach ($history in $histories) {
        $separationCount += [int]$history.separation_trigger_count
        foreach ($state in ([string]$history.states -split '\|')) {
            $target = if ([string]$history.trial_type -eq 'K1') {
                $stateCountsK1
            } else { $stateCountsK2 }
            if (-not $target.Contains($state)) { $target[$state] = 0 }
            $target[$state]++
        }
    }
    $lastCheckpoint = ''
    if ($checkpointFiles.Count -ne 0) {
        $last = $checkpointFiles | Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
        $lastCheckpoint = $last.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    }
    $now = [DateTimeOffset]::UtcNow
    $throughput15 = @($histories | Where-Object {
        try { [DateTimeOffset]::Parse($_.created_utc) -ge $now.AddMinutes(-15) }
        catch { $false }
    }).Count * 4.0
    $throughput60 = @($histories | Where-Object {
        try { [DateTimeOffset]::Parse($_.created_utc) -ge $now.AddMinutes(-60) }
        catch { $false }
    }).Count
    $classStatistics = Get-ClassStatistics $histories
    $workerLow = @(0.0, 0.0, 0.0, 0.0)
    $workerPoint = @(0.0, 0.0, 0.0, 0.0)
    $workerHigh = @(0.0, 0.0, 0.0, 0.0)
    foreach ($row in $registry) {
        if ($completedIds.Contains([string]$row.diagnostic_trial_id)) { continue }
        $estimate = Get-EtaEstimate $row $histories $classStatistics
        $worker = (([int]$row.global_trial_index - 1) %
            [int]$protocol.selected_worker_count)
        $workerLow[$worker] += $estimate.Low
        $workerPoint[$worker] += $estimate.Point
        $workerHigh[$worker] += $estimate.High
    }
    $completed = $completedIds.Count
    $etaLow = if ($histories.Count -eq 0) { $null } else {
        [double](($workerLow[0..([int]$protocol.selected_worker_count - 1)] |
            Measure-Object -Maximum).Maximum) / 3600.0
    }
    $etaPoint = if ($histories.Count -eq 0) { $null } else {
        [double](($workerPoint[0..([int]$protocol.selected_worker_count - 1)] |
            Measure-Object -Maximum).Maximum) / 3600.0
    }
    $etaHigh = if ($histories.Count -eq 0) { $null } else {
        [double](($workerHigh[0..([int]$protocol.selected_worker_count - 1)] |
            Measure-Object -Maximum).Maximum) / 3600.0
    }
    $etaConfidence = if ($completed -lt 12) { 'LOW' }
        elseif ($completed -lt 50) { 'MEDIUM' } else { 'HIGH' }
    $pauseRequested = Test-Path -LiteralPath `
        (Join-Path $RuntimeRoot 'control\pause.request') -PathType Leaf
    $tmpCount = @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'tmp') `
        -Filter '*.tmp' -File -ErrorAction SilentlyContinue).Count
    $lockCount = @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'workers') `
        -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count
    $activeCount = $activeProcesses.Count
    $finalAudit = Join-Path $RuntimeRoot 'merged\finalization_audit.json'
    if (Test-Path -LiteralPath $finalAudit -PathType Leaf) {
        $stage = 'FINALIZED_RESULTS_WRITTEN'
    } elseif ($completed -eq [int]$protocol.element_trial_count -and
            $activeCount -eq 0) {
        $stage = 'COMPLETE_CHECKPOINT_SET_108'
    } elseif ($pauseRequested -and $activeCount -eq 0 -and
            $tmpCount -eq 0 -and $lockCount -eq 0 -and $invalidCount -eq 0) {
        $stage = 'PAUSED_SAFE_TO_SHUTDOWN'
    } elseif ($pauseRequested) {
        $stage = 'PAUSE_REQUESTED'
    } elseif ($lastError -ne '') {
        $stage = 'ERROR_STOPPED'
    } elseif ($activeCount -gt 0) {
        $stage = "COMPACT_${activeCount}_WORKER_RUNNING"
    } else { $stage = 'PROTOCOL_COMMITTED' }
    $safe = $pauseRequested -and $activeCount -eq 0 -and $tmpCount -eq 0 -and
        $lockCount -eq 0 -and $invalidCount -eq 0
    $status = [ordered]@{
        protocol_version = $protocol.protocol_version
        protocol_stage = $stage
        gate_c0 = $protocol.gate_c0_status
        gate_c1 = $protocol.gate_c1_status
        gate_c2 = $protocol.gate_c2_status
        gate_c3 = $protocol.gate_c3_status
        gate_c4 = $protocol.gate_c4_status
        selected_worker_count = [int]$protocol.selected_worker_count
        selected_execution_mode = $protocol.selected_execution_mode
        completed_element_trials = $completed
        total_element_trials = [int]$protocol.element_trial_count
        completed_rows = $completedRows
        total_rows = [int]$protocol.row_count
        k1_completed = $k1Completed
        k1_total = 60
        k2_completed = $k2Completed
        k2_total = 48
        completed_per_stratum = $perStratum
        completed_per_profile = $perProfile
        workers = $workerViews
        active_worker_count = $activeCount
        valid_checkpoint_count = $completed
        invalid_checkpoint_count = $invalidCount
        tmp_checkpoint_count = $tmpCount
        current_trial_lock_count = $lockCount
        natural_separation_trigger_count = $separationCount
        k1_state_counts = $stateCountsK1
        k2_diagnostic_state_counts = $stateCountsK2
        last_checkpoint_utc = $lastCheckpoint
        rolling_15_minute_throughput_trials_per_hour = $throughput15
        rolling_60_minute_throughput_trials_per_hour = $throughput60
        runtime_class_statistics = $classStatistics
        eta_low_active_hours = $etaLow
        eta_point_active_hours = $etaPoint
        eta_high_active_hours = $etaHigh
        eta_confidence = $etaConfidence
        pause_requested = $pauseRequested
        safe_to_shutdown = $safe
        last_error = $lastError
        formal_6000_trial_status = $protocol.formal_6000_trial_status
        stage8_2_executed_flag = $false
        status_generated_utc = Get-UtcNowText
    }
    $statusRoot = Join-Path $RuntimeRoot 'status'
    $logsRoot = Join-Path $RuntimeRoot 'logs'
    Write-JsonAtomic (Join-Path $statusRoot 'latest_status.json') $status
    $etaText = if ($null -eq $etaPoint) { 'unavailable' } else {
        ('{0:N2} h [low {1:N2}, high {2:N2}]' -f
            $etaPoint, $etaLow, $etaHigh)
    }
    $workerText = ($workerViews | ForEach-Object {
        "Worker $('{0:D2}' -f $_.worker_id): PID $($_.pid) | " +
        "$($_.worker_state) | $($_.current_trial) | " +
        "elapsed $([Math]::Round($_.current_trial_elapsed_sec,1)) s"
    }) -join [Environment]::NewLine
    $text = @(
        'Stage8 Compact K1/K2 Diagnostic Status'
        "Protocol stage : $stage"
        "Execution mode : $($protocol.selected_execution_mode)"
        "Workers        : $($protocol.selected_worker_count) selected, $activeCount active"
        "Progress       : $completed / $($protocol.element_trial_count) element trials"
        "Rows           : $completedRows / $($protocol.row_count)"
        "K1 / K2       : $k1Completed / 60 | $k2Completed / 48"
        $workerText
        "Separation     : $separationCount natural triggers"
        "Throughput 60m : $throughput60 trials/hour"
        "ETA active     : $etaText, confidence $etaConfidence"
        "Pause requested: $pauseRequested"
        "Safe shutdown  : $safe"
        "Last checkpoint: $lastCheckpoint"
        "Last error     : $lastError"
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText((Join-Path $statusRoot 'latest_status.txt'),
        $text + [Environment]::NewLine, $Utf8NoBom)
    $historyPath = Join-Path $logsRoot 'status_history.csv'
    $historyRow = [pscustomobject]@{
        status_generated_utc = $status.status_generated_utc
        protocol_stage = $stage
        completed_element_trials = $completed
        completed_rows = $completedRows
        active_worker_count = $activeCount
        throughput_60m = $throughput60
        eta_point_active_hours = $etaPoint
        eta_high_active_hours = $etaHigh
        eta_confidence = $etaConfidence
        safe_to_shutdown = $safe
    }
    if (Test-Path -LiteralPath $historyPath -PathType Leaf) {
        $historyRow | Export-Csv -LiteralPath $historyPath -NoTypeInformation `
            -Append
    } else {
        $historyRow | Export-Csv -LiteralPath $historyPath -NoTypeInformation
    }
    return [pscustomobject]$status
}

function Register-StatusTask {
    Assert-NoForeignStage8StatusTask
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" ' +
        '-Action Status -RuntimeRoot "{1}" -RepoDir "{2}" -MatlabExe "{3}"'
    $arguments = $arguments -f $PSCommandPath, $RuntimeRoot, $RepoDir, $MatlabExe
    $taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15) `
        -RepetitionInterval (New-TimeSpan -Minutes 15)
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    Register-ScheduledTask -TaskName $StatusTaskName -Action $taskAction `
        -Trigger $trigger -Settings $settings `
        -Description 'Read-only Stage8 compact diagnostic status every 15 minutes.' `
        -Force | Out-Null
}

function Unregister-StatusTask {
    $task = Get-ScheduledTask -TaskName $StatusTaskName -ErrorAction SilentlyContinue
    if ($null -ne $task) {
        Unregister-ScheduledTask -TaskName $StatusTaskName -Confirm:$false
    }
}

function Invoke-Init {
    Assert-NoForeignStage8StatusTask
    Assert-NoMatlabCoordinatorOrLock | Out-Null
    $decisionPath = Join-Path $RuntimeRoot 'pilot\pilot_decision.json'
    $decision = Read-JsonFile $decisionPath
    if (-not ([bool]$decision.gate_c0_pass -and [bool]$decision.gate_c1_pass -and
            [bool]$decision.gate_c2_pass -and [bool]$decision.gate_c3_pass -and
            [bool]$decision.gate_c4_pass)) {
        throw 'Formal compact Init requires completed passing C0-C4.'
    }
    Initialize-ProtocolRoot $RuntimeRoot ([int]$decision.selected_worker_count) `
        @(1..108) ([string]$decision.selected_execution_mode) `
        'FORMAL_COMPACT_DIAGNOSTIC' 0 $decisionPath
    Register-StatusTask
    return Get-StatusSnapshot
}

function Start-SelectedWorkers {
    param([string]$Label)
    $protocol = Get-Protocol
    $active = @(Get-MatchingWorkerProcesses $RuntimeRoot)
    if ($active.Count -ne 0) {
        throw 'Compact workers are already active.'
    }
    return @(Start-WorkerSet $RuntimeRoot `
        ([int]$protocol.selected_worker_count) $Label)
}

function Invoke-Start {
    if (Test-Path -LiteralPath (Join-Path $RuntimeRoot 'control\pause.request') `
            -PathType Leaf) {
        throw 'Start is blocked by pause.request; use Resume.'
    }
    Assert-NoMatlabCoordinatorOrLock | Out-Null
    Invoke-RuntimeAudit $RuntimeRoot 'start_preflight'
    $started = @(Start-SelectedWorkers 'formal_start')
    Start-Sleep -Seconds 2
    return [pscustomobject]@{
        StartedProcessIds = @($started | ForEach-Object { $_.Id })
        Status = Get-StatusSnapshot
    }
}

function Invoke-Pause {
    Get-Protocol | Out-Null
    $request = Join-Path $RuntimeRoot 'control\pause.request'
    if (-not (Test-Path -LiteralPath $request -PathType Leaf)) {
        [System.IO.File]::WriteAllText($request,
            "requested_utc=$(Get-UtcNowText)`n" +
            "requested_by=MANUAL_POWERSHELL_ACTION`n", $Utf8NoBom)
    }
    return Get-StatusSnapshot
}

function Invoke-Resume {
    Get-Protocol | Out-Null
    if ((Get-MatchingWorkerProcesses $RuntimeRoot).Count -ne 0) {
        throw 'Resume requires all prior compact workers to be stopped.'
    }
    Assert-NoMatlabCoordinatorOrLock | Out-Null
    Archive-StaleRuntimeWrites $RuntimeRoot
    Invoke-RuntimeAudit $RuntimeRoot 'resume_preflight'
    Archive-PauseRequest $RuntimeRoot 'formal_resume'
    $started = @(Start-SelectedWorkers 'formal_resume')
    Start-Sleep -Seconds 2
    return [pscustomobject]@{
        StartedProcessIds = @($started | ForEach-Object { $_.Id })
        Status = Get-StatusSnapshot
    }
}

function Invoke-Finalize {
    $status = Get-StatusSnapshot
    $protocol = Get-Protocol
    if ($status.completed_element_trials -ne [int]$protocol.element_trial_count -or
            $status.completed_rows -ne [int]$protocol.row_count -or
            $status.active_worker_count -ne 0 -or
            $status.tmp_checkpoint_count -ne 0 -or
            $status.current_trial_lock_count -ne 0 -or
            $status.invalid_checkpoint_count -ne 0) {
        throw 'Finalize requires 108/108 valid inactive checkpoints and 180 rows.'
    }
    Assert-NoMatlabCoordinatorOrLock | Out-Null
    Invoke-RuntimeAudit $RuntimeRoot 'finalize_preflight'
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $RuntimeRoot
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');" +
        "stage8_compact_merge_report('$repo','$runtime');"
    Invoke-MatlabBatch $expression (Join-Path $RuntimeRoot 'logs\finalize.log')
    Unregister-StatusTask
    return Get-StatusSnapshot
}

Assert-Paths
switch ($Action) {
    'Pilot' { Invoke-Pilot }
    'Init' { Invoke-Init }
    'Start' { Invoke-Start }
    'Status' { Get-StatusSnapshot }
    'Pause' { Invoke-Pause }
    'Resume' { Invoke-Resume }
    'Finalize' { Invoke-Finalize }
    'RegisterStatusTask' { Register-StatusTask; Get-StatusSnapshot }
    'UnregisterStatusTask' { Unregister-StatusTask }
}
