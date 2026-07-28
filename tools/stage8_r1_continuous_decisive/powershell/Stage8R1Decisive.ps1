[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Init', 'Gates', 'Start', 'Status', 'Pause', 'Resume', 'Finalize')]
    [string]$Action,
    [string]$RuntimeRoot = 'E:\bs_innovation_runtime\stage8_r1_continuous_refinement_decisive_v1_f6ec19f',
    [string]$RepoDir = 'E:\bs_innovation',
    [string]$MatlabExe = 'E:\MATLABR2022b\bin\matlab.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProtocolVersion = 'STAGE8_R1_CONTINUOUS_REFINEMENT_DECISIVE_EXPERIMENT_V1'
$Authorization = 'AUTHORIZE_STAGE8_R1_CONTINUOUS_REFINEMENT_DECISIVE_EXPERIMENT_V1'
$ToolRoot = Split-Path -Parent $PSScriptRoot
$MatlabToolDir = Join-Path $ToolRoot 'matlab'
$StepRoot = Join-Path $RepoDir 'beamspace_ml_v18\source\stepwise_signal_model\steps\step_12_6_k12_bootstrap_resolution'
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
    $json = $Value | ConvertTo-Json -Depth 32
    [System.IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine,
        $script:Utf8NoBom)
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
    $coordinator = @($processes | Where-Object {
        $_.ProcessId -ne $selfId -and $_.CommandLine -match 'stage8.*coordinator|coordinator.*stage8'
    })
    $lockRoots = @('E:\bs_innovation_runtime\stage8_1b_a5r2_cellwise_7dc1e4c3\locks', (Join-Path $RuntimeRoot 'workers'))
    $locks = 0
    foreach ($root in $lockRoots) {
        $locks += @(Get-ChildItem -LiteralPath $root -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count
    }
    return [ordered]@{
        matlab_count = $matlab.Count
        mwpython_count = $mwpython.Count
        coordinator_count = $coordinator.Count
        active_lock_count = $locks
        checked_utc = Get-UtcNowText
    }
}

function Assert-NoMatlabCoordinatorOrLock {
    $audit = Get-ProcessAudit
    if ($audit.matlab_count -ne 0 -or $audit.mwpython_count -ne 0 -or
        $audit.coordinator_count -ne 0 -or $audit.active_lock_count -ne 0) {
        throw ('MATLAB/mwpython/coordinator/active-lock preflight failed: ' +
            "$($audit.matlab_count)/$($audit.mwpython_count)/$($audit.coordinator_count)/$($audit.active_lock_count)")
    }
    return $audit
}

function Assert-CleanCommittedTree {
    $status = (& git -C $RepoDir status --porcelain=v1 --untracked-files=all) -join [Environment]::NewLine
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        throw "A clean committed repository is required. Current status: $status"
    }
}

function Invoke-MatlabBatch {
    param([string]$Expression, [string]$LogPath)
    $parent = Split-Path -Parent $LogPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    & $MatlabExe -singleCompThread -logfile $LogPath -batch $Expression | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB batch failed with exit code $LASTEXITCODE. Log: $LogPath"
    }
}

function Start-MatlabWorker {
    param([string]$Root, [int]$WorkerId, [string]$Label)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');stage8_r1_worker('$repo','$runtime',$WorkerId);"
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $name = 'worker_{0:D2}_{1}_{2}.log' -f $WorkerId, $Label, $stamp
    $log = Join-Path (Join-Path $Root 'logs') $name
    return Start-Process -FilePath $MatlabExe -ArgumentList @(
        '-singleCompThread', '-logfile', $log, '-batch', $expression) -PassThru -WindowStyle Hidden
}

function Get-WorkerProcesses {
    param([string]$Root)
    return @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^MATLAB.*' -and $_.CommandLine -like "*$Root*" -and
        $_.CommandLine -match 'stage8_r1_worker'
    })
}

function Wait-WorkerProcesses {
    param([System.Diagnostics.Process[]]$Processes)
    foreach ($process in $Processes) {
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "Worker process $($process.Id) exited with $($process.ExitCode)."
        }
        $process.Dispose()
    }
}

function Start-WorkerSetAndWait {
    param([string]$Root, [int]$WorkerCount, [string]$Label)
    if (@(Get-WorkerProcesses $Root).Count -ne 0) {
        throw "R1 workers are already active for runtime $Root"
    }
    $processes = @()
    for ($workerId = 1; $workerId -le $WorkerCount; $workerId++) {
        $processes += Start-MatlabWorker $Root $workerId $Label
    }
    Wait-WorkerProcesses $processes
}

function Initialize-Runtime {
    param([string]$Root, [int]$WorkerCount, [int[]]$TrialIndices,
        [string]$RegistryKind, [string]$Role, [int]$PauseAfterCheckpointCount = -1)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $indices = '[' + (($TrialIndices | ForEach-Object { [string]$_ }) -join ' ') + ']'
    $expression = "addpath('$tool');stage8_r1_initialize_runtime('$repo','$runtime',$WorkerCount,$indices,'$RegistryKind','$Role',$PauseAfterCheckpointCount);"
    Invoke-MatlabBatch $expression (Join-Path $Root 'logs\initialize.log')
}

function Invoke-CompletedRuntimeAudit {
    param([string]$Root, [string]$Label, [int]$ExpectedTrials)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');s=stage8_r1_build_status('$repo','$runtime');assert(s.completed_element_trials==$ExpectedTrials);assert(s.valid_checkpoint_count==$ExpectedTrials);assert(s.invalid_checkpoint_count==0);assert(s.tmp_checkpoint_count==0);assert(s.current_trial_lock_count==0);assert(s.active_worker_count==0);assert(isempty(s.last_error));"
    $name = '{0}_audit.log' -f $Label
    Invoke-MatlabBatch $expression (Join-Path $Root (Join-Path 'logs' $name))
}

function Get-RawRuntimeStatus {
    param([string]$Root)
    $protocol = Read-JsonFile (Join-Path $Root 'protocol.json')
    $checkpointCount = @(Get-ChildItem -LiteralPath (Join-Path $Root 'checkpoints') -Filter '*.mat' -File -ErrorAction SilentlyContinue).Count
    $tmpCount = @(Get-ChildItem -LiteralPath (Join-Path $Root 'tmp') -Filter '*.tmp' -File -ErrorAction SilentlyContinue).Count
    $lockCount = @(Get-ChildItem -LiteralPath (Join-Path $Root 'workers') -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count
    $workers = @()
    $active = 0
    $lastError = ''
    foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $Root 'workers') -Filter 'worker_*_status.json' -File -ErrorAction SilentlyContinue)) {
        $worker = Read-JsonFile $file.FullName
        $workers += $worker
        if ($worker.worker_state -in @('STARTING', 'RUNNING')) { $active++ }
        if ([string]::IsNullOrWhiteSpace([string]$lastError) -and
            -not [string]::IsNullOrWhiteSpace([string]$worker.last_error)) {
            $lastError = [string]$worker.last_error
        }
    }
    $safe = $active -eq 0 -and $tmpCount -eq 0 -and $lockCount -eq 0
    $stage = if ($checkpointCount -eq [int]$protocol.element_trial_count -and $safe) {
        'READY_TO_FINALIZE'
    } elseif ((Test-Path -LiteralPath (Join-Path $Root 'control\pause.request')) -and $safe) {
        'PAUSED_SAFE_TO_SHUTDOWN'
    } elseif ($active -gt 0) {
        'WORKERS_RUNNING'
    } else {
        'RUNTIME_INITIALIZED'
    }
    return [ordered]@{
        protocol_version = $protocol.protocol_version
        protocol_stage = $stage
        completed_element_trials = $checkpointCount
        total_element_trials = [int]$protocol.element_trial_count
        completed_rows = 3 * $checkpointCount
        total_rows = [int]$protocol.row_count
        tmp_checkpoint_count = $tmpCount
        current_trial_lock_count = $lockCount
        active_worker_count = $active
        worker_states = $workers
        safe_to_shutdown = $safe
        ready_to_finalize = ($checkpointCount -eq [int]$protocol.element_trial_count -and $safe)
        last_error = $lastError
        formal_6000_trial_status = $protocol.formal_6000_trial_status
        stage8_2_executed_flag = [bool]$protocol.stage8_2_executed_flag
        generated_utc = Get-UtcNowText
    }
}

function Archive-PauseRequest {
    param([string]$Root, [string]$Label)
    $request = Join-Path $Root 'control\pause.request'
    if (-not (Test-Path -LiteralPath $request -PathType Leaf)) { return }
    $archive = Join-Path $Root 'control\archive'
    if (-not (Test-Path -LiteralPath $archive -PathType Container)) {
        New-Item -ItemType Directory -Path $archive -Force | Out-Null
    }
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $name = 'pause_{0}_{1}.request' -f $Label, $stamp
    Move-Item -LiteralPath $request -Destination (Join-Path $archive $name)
}

function Write-GateDecision {
    param([string]$GateRoot, [object]$R0R1, [object]$R2, [object]$R3)
    $selected = if ($R3.equivalent) { 2 } else { 1 }
    $mode = if ($selected -eq 2) { 'TWO_WORKER_RESUMABLE' } else { 'ONE_WORKER_RESUMABLE' }
    $result = [ordered]@{
        protocol_version = $ProtocolVersion
        gate_r0_pass = [bool]$R0R1.gate_r0_pass
        gate_r0_status = [string]$R0R1.gate_r0_status
        gate_r1_pass = [bool]$R0R1.gate_r1_pass
        gate_r1_status = [string]$R0R1.gate_r1_status
        gate_r2_pass = [bool]$R2.gate_r2_pass
        gate_r2_status = [string]$R2.status
        gate_r3_pass = [bool]$R3.gate_r3_pass
        gate_r3_status = [string]$R3.status
        worker_equivalent = [bool]$R3.equivalent
        selected_worker_count = $selected
        selected_execution_mode = $mode
        formal_6000_trial_status = 'FULL_STAGE8_1B_K1_VALIDATION_DEFERRED_NOT_FAILED'
        stage8_2_executed_flag = $false
        generated_utc = Get-UtcNowText
    }
    Write-JsonAtomic (Join-Path $GateRoot 'gate_decision.json') $result
    return $result
}

Assert-Paths

switch ($Action) {
    'Init' {
        Assert-CleanCommittedTree
        $audit = Assert-NoMatlabCoordinatorOrLock
        if (-not (Test-Path -LiteralPath $RuntimeRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null
        }
        foreach ($name in @('gates', 'logs', 'status')) {
            $path = Join-Path $RuntimeRoot $name
            if (-not (Test-Path -LiteralPath $path -PathType Container)) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
            }
        }
        $repo = ConvertTo-MatlabLiteral $RepoDir
        $tool = ConvertTo-MatlabLiteral $MatlabToolDir
        Invoke-MatlabBatch "addpath('$tool');stage8_r1_context('$repo',true);" (Join-Path $RuntimeRoot 'logs\init_preflight.log')
        $preflight = [ordered]@{
            protocol_version = $ProtocolVersion
            authorization = $Authorization
            process_audit = $audit
            repository_head = (& git -C $RepoDir rev-parse HEAD).Trim()
            initialized_utc = Get-UtcNowText
        }
        Write-JsonAtomic (Join-Path $RuntimeRoot 'init_preflight.json') $preflight
        $preflight | ConvertTo-Json -Depth 8
    }
    'Gates' {
        Assert-CleanCommittedTree
        $audit = Assert-NoMatlabCoordinatorOrLock
        $gateRoot = Join-Path $RuntimeRoot 'gates'
        if (-not (Test-Path -LiteralPath $gateRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $gateRoot -Force | Out-Null
        }
        $auditPath = Join-Path $gateRoot 'prelaunch_process_audit.json'
        Write-JsonAtomic $auditPath $audit
        $repo = ConvertTo-MatlabLiteral $RepoDir
        $tool = ConvertTo-MatlabLiteral $MatlabToolDir
        $gates = ConvertTo-MatlabLiteral $gateRoot
        $auditLiteral = ConvertTo-MatlabLiteral $auditPath
        Invoke-MatlabBatch "addpath('$tool');stage8_r1_run_gates('$repo','$gates','$auditLiteral');" (Join-Path $gateRoot 'r0_r1.log')
        $r0r1 = Read-JsonFile (Join-Path $gateRoot 'r0_r1_result.json')

        $r2Full = Join-Path $gateRoot 'r2_uninterrupted'
        $r2Resume = Join-Path $gateRoot 'r2_pause_resume'
        foreach ($root in @($r2Full, $r2Resume)) {
            if (Test-Path -LiteralPath $root) { throw "Gate runtime already exists: $root" }
        }
        Initialize-Runtime $r2Full 1 @(1, 2) 'R2' 'GATE_R2_UNINTERRUPTED'
        Start-WorkerSetAndWait $r2Full 1 'r2_full'
        Invoke-CompletedRuntimeAudit $r2Full 'r2_full' 2
        Initialize-Runtime $r2Resume 1 @(1, 2) 'R2' 'GATE_R2_PAUSE_RESUME' 1
        Start-WorkerSetAndWait $r2Resume 1 'r2_pause'
        $paused = Get-RawRuntimeStatus $r2Resume
        if ($paused.completed_element_trials -ne 1 -or -not $paused.safe_to_shutdown) {
            throw 'Gate R2 did not reach a safe one-checkpoint pause boundary.'
        }
        Archive-PauseRequest $r2Resume 'r2'
        Start-WorkerSetAndWait $r2Resume 1 'r2_resume'
        Invoke-CompletedRuntimeAudit $r2Resume 'r2_resume' 2
        $r2Compare = Join-Path $gateRoot 'r2_comparison.json'
        $left = ConvertTo-MatlabLiteral $r2Full
        $right = ConvertTo-MatlabLiteral $r2Resume
        $comparison = ConvertTo-MatlabLiteral $r2Compare
        Invoke-MatlabBatch "addpath('$tool');stage8_r1_compare_runtime_roots('$repo','$left','$right','$comparison','R2');" (Join-Path $gateRoot 'r2_compare.log')
        $r2Comparison = Read-JsonFile $r2Compare
        $r2 = [ordered]@{ gate_r2_pass = [bool]$r2Comparison.pass; status = 'R2_CHECKPOINT_RESUME_PASS'; comparison = $r2Comparison }
        Write-JsonAtomic (Join-Path $gateRoot 'gate_r2_result.json') $r2
        if (-not $r2.gate_r2_pass) { throw 'Gate R2 checkpoint/resume equivalence failed.' }

        $r3One = Join-Path $gateRoot 'r3_one_worker'
        $r3Two = Join-Path $gateRoot 'r3_two_worker'
        foreach ($root in @($r3One, $r3Two)) {
            if (Test-Path -LiteralPath $root) { throw "Gate runtime already exists: $root" }
        }
        $r3Indices = @(1, 16, 17, 24)
        Initialize-Runtime $r3One 1 $r3Indices 'R3' 'GATE_R3_ONE_WORKER'
        Start-WorkerSetAndWait $r3One 1 'r3_one'
        Invoke-CompletedRuntimeAudit $r3One 'r3_one' 4
        Initialize-Runtime $r3Two 2 $r3Indices 'R3' 'GATE_R3_TWO_WORKER'
        Start-WorkerSetAndWait $r3Two 2 'r3_two'
        Invoke-CompletedRuntimeAudit $r3Two 'r3_two' 4
        $r3Compare = Join-Path $gateRoot 'r3_comparison.json'
        $left = ConvertTo-MatlabLiteral $r3One
        $right = ConvertTo-MatlabLiteral $r3Two
        $comparison = ConvertTo-MatlabLiteral $r3Compare
        Invoke-MatlabBatch "addpath('$tool');stage8_r1_compare_runtime_roots('$repo','$left','$right','$comparison','R3');" (Join-Path $gateRoot 'r3_compare.log')
        $r3Comparison = Read-JsonFile $r3Compare
        $r3 = [ordered]@{
            gate_r3_pass = $true
            status = if ($r3Comparison.pass) { 'R3_ONE_TWO_WORKER_EQUIVALENCE_PASS' } else { 'R3_DIFFERENCE_RECORDED_ONE_WORKER_SELECTED' }
            equivalent = [bool]$r3Comparison.pass
            comparison = $r3Comparison
        }
        Write-JsonAtomic (Join-Path $gateRoot 'gate_r3_result.json') $r3
        $decision = Write-GateDecision $gateRoot $r0r1 $r2 $r3
        $decision | ConvertTo-Json -Depth 12
    }
    'Start' {
        Assert-CleanCommittedTree
        $null = Assert-NoMatlabCoordinatorOrLock
        $gateRoot = Join-Path $RuntimeRoot 'gates'
        $decision = Read-JsonFile (Join-Path $gateRoot 'gate_decision.json')
        if (-not ($decision.gate_r0_pass -and $decision.gate_r1_pass -and $decision.gate_r2_pass -and $decision.gate_r3_pass)) {
            throw 'All R0-R3 gate statuses must pass before formal execution.'
        }
        $protocolPath = Join-Path $RuntimeRoot 'protocol.json'
        if (-not (Test-Path -LiteralPath $protocolPath -PathType Leaf)) {
            Initialize-Runtime $RuntimeRoot ([int]$decision.selected_worker_count) (1..24) 'FORMAL' 'FORMAL_24_TRIAL'
        }
        $protocol = Read-JsonFile $protocolPath
        Start-WorkerSetAndWait $RuntimeRoot ([int]$protocol.selected_worker_count) 'formal'
        $raw = Get-RawRuntimeStatus $RuntimeRoot
        Write-JsonAtomic (Join-Path $RuntimeRoot 'status\latest_status.json') $raw
        $raw | ConvertTo-Json -Depth 12
    }
    'Status' {
        $raw = Get-RawRuntimeStatus $RuntimeRoot
        Write-JsonAtomic (Join-Path $RuntimeRoot 'status\latest_status.json') $raw
        $raw | ConvertTo-Json -Depth 12
    }
    'Pause' {
        $request = Join-Path $RuntimeRoot 'control\pause.request'
        $parent = Split-Path -Parent $request
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            throw "Runtime control directory is missing: $parent"
        }
        $text = 'requested_utc=' + (Get-UtcNowText) + [Environment]::NewLine + 'requested_by=manual_pause' + [Environment]::NewLine
        [System.IO.File]::WriteAllText($request, $text, $Utf8NoBom)
        Get-RawRuntimeStatus $RuntimeRoot | ConvertTo-Json -Depth 12
    }
    'Resume' {
        Assert-CleanCommittedTree
        if (@(Get-WorkerProcesses $RuntimeRoot).Count -ne 0) {
            throw 'Cannot resume while a MATLAB worker is still active.'
        }
        $protocol = Read-JsonFile (Join-Path $RuntimeRoot 'protocol.json')
        Archive-PauseRequest $RuntimeRoot 'manual_resume'
        Start-WorkerSetAndWait $RuntimeRoot ([int]$protocol.selected_worker_count) 'resume'
        Get-RawRuntimeStatus $RuntimeRoot | ConvertTo-Json -Depth 12
    }
    'Finalize' {
        Assert-CleanCommittedTree
        if (@(Get-WorkerProcesses $RuntimeRoot).Count -ne 0) {
            throw 'Cannot finalize while a MATLAB worker is active.'
        }
        $outputs = @(
            (Join-Path $RepoDir 'innovation-mining\24_stage8_r1_continuous_refinement_decisive_experiment.md'),
            (Join-Path $RepoDir 'innovation-mining\24_stage8_r1_continuous_refinement_decisive_trials.csv'),
            (Join-Path $RepoDir 'innovation-mining\24_stage8_r1_continuous_refinement_decisive_summary.csv'),
            (Join-Path $RepoDir 'innovation-mining\24_stage8_r1_continuous_refinement_method_comparison.csv')
        )
        foreach ($path in $outputs) {
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                throw "Finalize refuses to overwrite existing result: $path"
            }
        }
        $repo = ConvertTo-MatlabLiteral $RepoDir
        $runtime = ConvertTo-MatlabLiteral $RuntimeRoot
        $tool = ConvertTo-MatlabLiteral $MatlabToolDir
        $out = ConvertTo-MatlabLiteral (Join-Path $RepoDir 'innovation-mining')
        $expression = "addpath('$tool');o=stage8_r1_merge_analyze('$repo','$runtime','$out');assert(height(o.trials)==72);assert(height(o.summary)==3);assert(height(o.comparison)==8);assert(~o.decision.stage8_2_executed_flag);"
        Invoke-MatlabBatch $expression (Join-Path $RuntimeRoot 'logs\finalize.log')
        Get-RawRuntimeStatus $RuntimeRoot | ConvertTo-Json -Depth 12
    }
}
