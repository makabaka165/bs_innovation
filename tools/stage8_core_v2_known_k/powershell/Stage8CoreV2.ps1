[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Init', 'Gates', 'Start', 'Status', 'Pause', 'Resume', 'Finalize')]
    [string]$Action,
    [string]$RuntimeRoot = 'E:\bs_innovation_runtime\stage8_core_v2_known_k_center_difference_v2_b606840',
    [string]$RepoDir = 'E:\bs_innovation',
    [string]$MatlabExe = 'E:\MATLABR2022b\bin\matlab.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ToolRoot = Split-Path -Parent $PSScriptRoot
$MatlabToolDir = Join-Path $ToolRoot 'matlab'
$PromptPath = Join-Path $RepoDir 'innovation-mining\stage8_execution_prompts\active\005_stage8_core_v2_known_k_center_difference_pruning_v2.md'
$GateRoot = Join-Path $RuntimeRoot 'gates'
$OneGateRoot = Join-Path $GateRoot 'one_worker'
$TwoGateRoot = Join-Path $GateRoot 'two_worker'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function ConvertTo-MatlabLiteral { param([string]$Value) return $Value.Replace("'", "''") }
function Get-UtcNowText { return [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }

function Write-JsonAtomic {
    param([string]$Path, [object]$Value)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $temporary = "$Path.tmp"
    $json = $Value | ConvertTo-Json -Depth 32
    [IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine, $Utf8NoBom)
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing JSON file: $Path" }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Assert-Paths {
    foreach ($path in @($RepoDir, $MatlabToolDir, (Split-Path -Parent $PromptPath))) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "Required directory not found: $path" }
    }
    if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) { throw "MATLAB R2022b executable not found: $MatlabExe" }
    if (-not (Test-Path -LiteralPath $PromptPath -PathType Leaf)) { throw "Active prompt is missing: $PromptPath" }
}

function Assert-CleanCommittedTree {
    $status = (& git -C $RepoDir status --porcelain=v1 --untracked-files=all) -join [Environment]::NewLine
    if (-not [string]::IsNullOrWhiteSpace($status)) { throw "A clean committed repository is required. Current status: $status" }
}

function Get-ProcessAudit {
    $selfId = $PID
    $processes = @(Get-CimInstance Win32_Process)
    $matlab = @($processes | Where-Object { $_.Name -match '^MATLAB.*' })
    $coordinator = @($processes | Where-Object {
        $_.ProcessId -ne $selfId -and $_.CommandLine -match 'stage8.*coordinator|coordinator.*stage8'
    })
    $lockCount = @(Get-ChildItem -LiteralPath $RuntimeRoot -Recurse -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count
    return [ordered]@{
        matlab_count = $matlab.Count
        lock_count = $lockCount
        coordinator_count = $coordinator.Count
        prompt_sha256 = (Get-FileHash -LiteralPath $PromptPath -Algorithm SHA256).Hash.ToLowerInvariant()
        checked_utc = Get-UtcNowText
    }
}

function Assert-NoActiveRuntime {
    $audit = Get-ProcessAudit
    if ($audit.matlab_count -ne 0 -or $audit.lock_count -ne 0 -or $audit.coordinator_count -ne 0) {
        throw "MATLAB/coordinator/current-lock preflight failed: $($audit.matlab_count)/$($audit.coordinator_count)/$($audit.lock_count)"
    }
    return $audit
}

function Invoke-MatlabBatch {
    param([string]$Expression, [string]$LogPath)
    $parent = Split-Path -Parent $LogPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    & $MatlabExe -singleCompThread -logfile $LogPath -batch $Expression | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "MATLAB batch failed with exit code $LASTEXITCODE. Log: $LogPath" }
}

function Start-MatlabWorker {
    param([string]$Root, [int]$WorkerId, [string]$Label)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$tool');stage8_core_v2_worker('$repo','$runtime',$WorkerId);"
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $log = Join-Path (Join-Path $Root 'logs') ('worker_{0:D2}_{1}_{2}.log' -f $WorkerId, $Label, $stamp)
    return Start-Process -FilePath $MatlabExe -ArgumentList @('-singleCompThread','-logfile',$log,'-batch',$expression) -PassThru -WindowStyle Hidden
}

function Get-WorkerProcesses {
    param([string]$Root)
    return @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^MATLAB.*' -and $_.CommandLine -like "*$Root*" -and $_.CommandLine -match 'stage8_core_v2_worker'
    })
}

function Start-WorkerSetAndWait {
    param([string]$Root, [int]$WorkerCount, [string]$Label)
    if (@(Get-WorkerProcesses $Root).Count -ne 0) { throw "Workers are already active for $Root" }
    $processes = @()
    for ($workerId = 1; $workerId -le $WorkerCount; $workerId++) { $processes += Start-MatlabWorker $Root $workerId $Label }
    foreach ($process in $processes) {
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw "Worker process $($process.Id) exited with $($process.ExitCode)." }
        $process.Dispose()
    }
}

function Initialize-Runtime {
    param([string]$Root, [int]$WorkerCount, [int[]]$TrialIndices, [string]$RegistryKind, [string]$Role)
    $repo = ConvertTo-MatlabLiteral $RepoDir
    $runtime = ConvertTo-MatlabLiteral $Root
    $tool = ConvertTo-MatlabLiteral $MatlabToolDir
    $indices = '[' + (($TrialIndices | ForEach-Object { [string]$_ }) -join ' ') + ']'
    $expression = "addpath('$tool');stage8_core_v2_initialize_runtime('$repo','$runtime',$WorkerCount,$indices,'$RegistryKind','$Role');"
    Invoke-MatlabBatch $expression (Join-Path $Root 'logs\initialize.log')
}

function Get-RuntimeStatus {
    $protocolPath = Join-Path $RuntimeRoot 'protocol.json'
    $checkpointPath = Join-Path $RuntimeRoot 'checkpoints'
    $protocol = $null
    if (Test-Path -LiteralPath $protocolPath -PathType Leaf) { $protocol = Read-JsonFile $protocolPath }
    $checkpointCount = @(Get-ChildItem -LiteralPath $checkpointPath -Filter '*.mat' -File -ErrorAction SilentlyContinue).Count
    $tmpCount = @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'tmp') -Filter '*.tmp' -File -ErrorAction SilentlyContinue).Count
    $lockCount = @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'workers') -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count
    $active = @(Get-WorkerProcesses $RuntimeRoot).Count
    $total = if ($null -eq $protocol) { 24 } else { [int]$protocol.element_trial_count }
    $stage = if ($checkpointCount -eq $total -and $active -eq 0 -and $tmpCount -eq 0 -and $lockCount -eq 0) { 'READY_TO_FINALIZE' }
        elseif ($active -gt 0) { 'WORKERS_RUNNING' }
        elseif (Test-Path -LiteralPath (Join-Path $RuntimeRoot 'control\pause.request') -PathType Leaf) { 'PAUSED_SAFE_TO_SHUTDOWN' }
        else { 'RUNTIME_INITIALIZED' }
    return [ordered]@{
        protocol_stage = $stage
        completed_element_trials = $checkpointCount
        total_element_trials = $total
        completed_rows = 3 * $checkpointCount
        total_rows = if ($null -eq $protocol) { 72 } else { [int]$protocol.row_count }
        tmp_checkpoint_count = $tmpCount
        current_trial_lock_count = $lockCount
        active_worker_count = $active
        selected_execution_mode = if ($null -eq $protocol) { '' } else { [string]$protocol.selected_execution_mode }
        generated_utc = Get-UtcNowText
    }
}

Assert-Paths
switch ($Action) {
    'Init' {
        Assert-CleanCommittedTree
        $null = Assert-NoActiveRuntime
        foreach ($dir in @($RuntimeRoot, (Join-Path $RuntimeRoot 'gates'), (Join-Path $RuntimeRoot 'checkpoints'), (Join-Path $RuntimeRoot 'tmp'), (Join-Path $RuntimeRoot 'workers'), (Join-Path $RuntimeRoot 'logs'), (Join-Path $RuntimeRoot 'control'))) {
            if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        }
        Write-JsonAtomic (Join-Path $RuntimeRoot 'init.json') ([ordered]@{ protocol = 'STAGE8_CORE_V2_KNOWN_K_CENTER_DIFFERENCE_PRUNING_V2'; initialized_utc = Get-UtcNowText })
        Get-RuntimeStatus | ConvertTo-Json -Depth 12
    }
    'Gates' {
        Assert-CleanCommittedTree
        $audit = Assert-NoActiveRuntime
        if (-not (Test-Path -LiteralPath $GateRoot -PathType Container)) { New-Item -ItemType Directory -Path $GateRoot -Force | Out-Null }
        Write-JsonAtomic (Join-Path $GateRoot 'process_audit.json') $audit
        $repo = ConvertTo-MatlabLiteral $RepoDir
        $gate = ConvertTo-MatlabLiteral $GateRoot
        $auditPath = ConvertTo-MatlabLiteral (Join-Path $GateRoot 'process_audit.json')
        $tool = ConvertTo-MatlabLiteral $MatlabToolDir
        Invoke-MatlabBatch "addpath('$tool');stage8_core_v2_run_gates('$repo','$gate','$auditPath','G0');" (Join-Path $GateRoot 'g0.log')
        Initialize-Runtime $OneGateRoot 1 @(8,19) 'GATES' 'G1_G2_ONE_WORKER'
        Initialize-Runtime $TwoGateRoot 2 @(8,19) 'GATES' 'G1_G2_TWO_WORKER'
        Start-WorkerSetAndWait $OneGateRoot 1 'gate-one'
        Start-WorkerSetAndWait $TwoGateRoot 2 'gate-two'
        $one = ConvertTo-MatlabLiteral $OneGateRoot
        $two = ConvertTo-MatlabLiteral $TwoGateRoot
        Invoke-MatlabBatch "addpath('$tool');stage8_core_v2_run_gates('$repo','$gate','$auditPath','G1_G2','$one','$two');" (Join-Path $GateRoot 'g1_g2.log')
        Read-JsonFile (Join-Path $GateRoot 'gate_decision.json') | ConvertTo-Json -Depth 12
    }
    'Start' {
        Assert-CleanCommittedTree
        $null = Assert-NoActiveRuntime
        $decision = Read-JsonFile (Join-Path $GateRoot 'gate_decision.json')
        if (-not [bool]$decision.gate_g0_pass -or -not [bool]$decision.gate_g1_pass -or -not [bool]$decision.gate_g2_pass) { throw 'G0-G2 must pass before formal execution.' }
        $protocolPath = Join-Path $RuntimeRoot 'protocol.json'
        if (-not (Test-Path -LiteralPath $protocolPath -PathType Leaf)) {
            Initialize-Runtime $RuntimeRoot ([int]$decision.selected_worker_count) (1..24) 'FORMAL' 'FORMAL_24_TRIAL'
        }
        $protocol = Read-JsonFile $protocolPath
        Start-WorkerSetAndWait $RuntimeRoot ([int]$protocol.selected_worker_count) 'formal'
        Get-RuntimeStatus | ConvertTo-Json -Depth 12
    }
    'Status' { Get-RuntimeStatus | ConvertTo-Json -Depth 12 }
    'Pause' {
        $request = Join-Path $RuntimeRoot 'control\pause.request'
        [IO.File]::WriteAllText($request, "requested_utc=$(Get-UtcNowText)`nrequested_by=manual_pause`n", $Utf8NoBom)
        Get-RuntimeStatus | ConvertTo-Json -Depth 12
    }
    'Resume' {
        Assert-CleanCommittedTree
        $null = Assert-NoActiveRuntime
        $protocol = Read-JsonFile (Join-Path $RuntimeRoot 'protocol.json')
        $request = Join-Path $RuntimeRoot 'control\pause.request'
        if (Test-Path -LiteralPath $request -PathType Leaf) { Move-Item -LiteralPath $request -Destination (Join-Path $RuntimeRoot ('control\pause.' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '.request')) -Force }
        Start-WorkerSetAndWait $RuntimeRoot ([int]$protocol.selected_worker_count) 'resume'
        Get-RuntimeStatus | ConvertTo-Json -Depth 12
    }
    'Finalize' {
        Assert-CleanCommittedTree
        $null = Assert-NoActiveRuntime
        $repo = ConvertTo-MatlabLiteral $RepoDir
        $runtime = ConvertTo-MatlabLiteral $RuntimeRoot
        $out = ConvertTo-MatlabLiteral (Join-Path $RepoDir 'innovation-mining')
        $tool = ConvertTo-MatlabLiteral $MatlabToolDir
        Invoke-MatlabBatch "addpath('$tool');o=stage8_core_v2_finalize('$repo','$runtime','$out');assert(height(o.trials)==72);assert(height(o.summary)==3);assert(height(o.comparison)==8);assert(~o.decision.stage8_2_executed_flag);" (Join-Path $RuntimeRoot 'logs\finalize.log')
        Get-RuntimeStatus | ConvertTo-Json -Depth 12
    }
}
