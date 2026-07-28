[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Init', 'Pilot', 'Start', 'Pause', 'Resume', 'Status',
        'ForceStop', 'RegisterStatusTask', 'UnregisterStatusTask', 'Finalize')]
    [string]$Action,

    [string]$RuntimeRoot =
        'E:\bs_innovation_runtime\stage8_1b_k1_validation_sharded_resumable_v2_9bfa65e6',

    [string]$RepoDir = 'E:\bs_innovation',

    [string]$MatlabExe = 'E:\MATLABR2022b\bin\matlab.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProtocolVersion = 'STAGE8_1B_K1_VALIDATION_SHARDED_RESUMABLE_V2'
$Authorization = 'AUTHORIZE_STAGE8_1B_K1_VALIDATION_SHARDED_RESUMABLE_V2'
$StatusTaskName = 'BSInnovation-Stage8K1-Status'
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
    $json = $Value | ConvertTo-Json -Depth 12
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
    param([bool]$RequireMatlab)
    if (-not (Test-Path -LiteralPath $RepoDir -PathType Container)) {
        throw "Repository not found: $RepoDir"
    }
    if ($RequireMatlab -and -not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {
        throw "MATLAB R2022b executable not found: $MatlabExe"
    }
    if (-not (Test-Path -LiteralPath $MatlabToolDir -PathType Container)) {
        throw "MATLAB tool directory not found: $MatlabToolDir"
    }
}

function Assert-NoStage8Matlab {
    $processes = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^(MATLAB|mwpython).*' -or
        $_.CommandLine -match 'stage8_1b_sharded_worker'
    })
    if ($processes.Count -ne 0) {
        $description = ($processes | ForEach-Object {
            "PID=$($_.ProcessId) Name=$($_.Name) Command=$($_.CommandLine)"
        }) -join [Environment]::NewLine
        throw "Stage8/MATLAB processes must be zero before this action.`n$description"
    }
    $selfProcessId = $PID
    $coordinators = @(Get-CimInstance Win32_Process | Where-Object {
        $_.ProcessId -ne $selfProcessId -and
        $_.CommandLine -match 'stage8.*coordinator|coordinator.*stage8'
    })
    $calibrationLockRoot =
        'E:\bs_innovation_runtime\stage8_1b_a5r2_cellwise_7dc1e4c3\locks'
    $activeLocks = @(Get-ChildItem -LiteralPath $calibrationLockRoot -File `
        -ErrorAction SilentlyContinue)
    if ($coordinators.Count -ne 0 -or $activeLocks.Count -ne 0) {
        throw "Coordinator/active-lock preflight failed: $($coordinators.Count)/$($activeLocks.Count)."
    }
}

function Invoke-MatlabBatch {
    param(
        [string]$Expression,
        [string]$LogPath
    )
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
    param(
        [string]$Expression,
        [string]$LogPath
    )
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
    param(
        [string]$Root,
        [int]$WorkerId,
        [string]$Label
    )
    $repoLiteral = ConvertTo-MatlabLiteral $RepoDir
    $rootLiteral = ConvertTo-MatlabLiteral $Root
    $toolLiteral = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$toolLiteral');" +
        "stage8_1b_sharded_worker('$repoLiteral','$rootLiteral',$WorkerId);"
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $logPath = Join-Path $Root "logs\worker_$('{0:D2}' -f $WorkerId)_${Label}_$stamp.log"
    $process = Start-MatlabExpression -Expression $expression -LogPath $logPath
    $pidPath = Join-Path $Root "workers\worker_$('{0:D2}' -f $WorkerId).pid"
    [System.IO.File]::WriteAllText($pidPath, "$($process.Id)`n", $script:Utf8NoBom)
    return $process
}

function Get-MatchingWorkerProcesses {
    param([string]$Root)
    return @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^MATLAB.*' -and
        $_.CommandLine -like "*$Root*" -and
        $_.CommandLine -match 'stage8_1b_sharded_worker'
    })
}

function Get-SystemMemorySample {
    $os = Get-CimInstance Win32_OperatingSystem
    $total = [double]$os.TotalVisibleMemorySize * 1024
    $available = [double]$os.FreePhysicalMemory * 1024
    $utilization = if ($total -gt 0) { ($total - $available) / $total } else { 1.0 }
    $pages = 0.0
    try {
        $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
        $pages = [double]$memory.PagesInputPerSec
    } catch {
        $pages = 0.0
    }
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
    $peakPrivate = 0.0
    $peakPrivateByWorker = @()
    for ($processIndex = 0; $processIndex -lt $Processes.Count; $processIndex++) {
        $peakPrivateByWorker += 0.0
    }
    $peakUtilization = 0.0
    $minimumAvailable = [double]::PositiveInfinity
    $pageSamples = New-Object System.Collections.Generic.List[double]
    $pauseCreated = $false
    while ($true) {
        $active = 0
        for ($processIndex = 0; $processIndex -lt $Processes.Count; $processIndex++) {
            $process = $Processes[$processIndex]
            $process.Refresh()
            if (-not $process.HasExited) {
                $active++
                try {
                    $privateNow = [double]$process.PrivateMemorySize64
                    if ($privateNow -gt $peakPrivateByWorker[$processIndex]) {
                        $peakPrivateByWorker[$processIndex] = $privateNow
                    }
                    if ($privateNow -gt $peakPrivate) { $peakPrivate = $privateNow }
                } catch { }
            }
        }
        $sample = Get-SystemMemorySample
        if ($sample.Utilization -gt $peakUtilization) {
            $peakUtilization = $sample.Utilization
        }
        if ($sample.AvailableBytes -lt $minimumAvailable) {
            $minimumAvailable = $sample.AvailableBytes
        }
        $pageSamples.Add($sample.PagesInputPerSec)
        if ($PauseAfterCheckpointCount -ge 0 -and -not $pauseCreated) {
            $completed = @(Get-ChildItem -LiteralPath (Join-Path $Root 'checkpoints') `
                -Filter '*.mat' -File -ErrorAction SilentlyContinue).Count
            if ($completed -ge $PauseAfterCheckpointCount) {
                $requestPath = Join-Path $Root 'control\pause.request'
                [System.IO.File]::WriteAllText($requestPath,
                    "pilot_pause_requested_utc=$(Get-UtcNowText)`n", $script:Utf8NoBom)
                $pauseCreated = $true
            }
        }
        if ($active -eq 0) { break }
        Start-Sleep -Seconds 2
    }
    $stopwatch.Stop()
    $exitCodes = @()
    foreach ($process in $Processes) {
        $process.WaitForExit()
        $exitCodes += $process.ExitCode
        $process.Dispose()
    }
    $highPageSamples = @($pageSamples | Where-Object { $_ -ge 1000 }).Count
    $sustainedThrashing = $false
    if ($pageSamples.Count -ge 5 -and
            $highPageSamples -ge [Math]::Ceiling($pageSamples.Count / 2.0)) {
        $sustainedThrashing = $true
    }
    return [pscustomobject]@{
        WallSec = $stopwatch.Elapsed.TotalSeconds
        PeakPrivateBytes = $peakPrivate
        PeakPrivateBytesByWorker = $peakPrivateByWorker
        PeakTotalMemoryUtilization = $peakUtilization
        MinimumAvailablePhysicalBytes = $minimumAvailable
        SustainedPagefileThrashing = $sustainedThrashing
        ExitCodes = $exitCodes
        PauseCreated = $pauseCreated
    }
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

function Get-CheckpointIdentity {
    param([string]$Root)
    return @(Get-ChildItem -LiteralPath (Join-Path $Root 'checkpoints') `
        -Filter '*.mat' -File | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            Length = $_.Length
            LastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('o')
            SHA256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
    })
}

function Test-IdentityUnchanged {
    param([object[]]$Before, [string]$Root)
    $after = Get-CheckpointIdentity -Root $Root
    foreach ($item in $Before) {
        $match = @($after | Where-Object { $_.Name -eq $item.Name })
        if ($match.Count -ne 1 -or $match[0].Length -ne $item.Length -or
                $match[0].LastWriteTimeUtc -ne $item.LastWriteTimeUtc -or
                $match[0].SHA256 -ne $item.SHA256) {
            return $false
        }
    }
    return $true
}

function Test-PilotSafePause {
    param([string]$Root, [int]$WorkerCount)
    if ((Get-MatchingWorkerProcesses -Root $Root).Count -ne 0) { return $false }
    if (@(Get-ChildItem -LiteralPath (Join-Path $Root 'tmp') -Filter '*.tmp' `
            -File -ErrorAction SilentlyContinue).Count -ne 0) { return $false }
    if (@(Get-ChildItem -LiteralPath (Join-Path $Root 'workers') `
            -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count -ne 0) {
        return $false
    }
    for ($workerId = 1; $workerId -le $WorkerCount; $workerId++) {
        $statusPath = Join-Path $Root `
            "workers\worker_$('{0:D2}' -f $workerId)_status.json"
        if (-not (Test-Path -LiteralPath $statusPath -PathType Leaf)) { return $false }
        $workerStatus = Read-JsonFile $statusPath
        if ([string]$workerStatus.worker_state -ne 'PAUSED_SAFE') { return $false }
    }
    return $true
}

function Get-CheckpointActiveSeconds {
    param([string]$Root, [int]$WorkerCount)
    $workerTotals = @()
    for ($workerId = 1; $workerId -le $WorkerCount; $workerId++) {
        $historyPath = Join-Path $Root `
            "logs\worker_$('{0:D2}' -f $workerId)_checkpoint_history.csv"
        if (-not (Test-Path -LiteralPath $historyPath -PathType Leaf)) {
            $workerTotals += 0.0
            continue
        }
        $values = @(Import-Csv -LiteralPath $historyPath | ForEach-Object {
            [double]$_.runtime_sec
        })
        if ($values.Count -eq 0) {
            $workerTotals += 0.0
        } else {
            $workerTotals += [double](($values | Measure-Object -Sum).Sum)
        }
    }
    if ($workerTotals.Count -eq 0) { return 0.0 }
    return [double](($workerTotals | Measure-Object -Maximum).Maximum)
}

function Write-PilotProgress {
    param([string]$PilotRoot, [string]$Stage, [string]$Detail)
    Write-JsonAtomic -Path (Join-Path $PilotRoot 'pilot_progress.json') -Value `
        ([ordered]@{
            protocol_version = $ProtocolVersion
            protocol_stage = $Stage
            detail = $Detail
            updated_utc = Get-UtcNowText
        })
}

function Invoke-PilotRootInit {
    param([string]$Root, [int]$WorkerCount, [string]$LogPath)
    $repoLiteral = ConvertTo-MatlabLiteral $RepoDir
    $rootLiteral = ConvertTo-MatlabLiteral $Root
    $toolLiteral = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$toolLiteral');" +
        "stage8_1b_initialize_pilot_runtime('$repoLiteral','$rootLiteral',$WorkerCount);"
    Invoke-MatlabBatch -Expression $expression -LogPath $LogPath
}

function Invoke-Pilot {
    Assert-NoStage8Matlab
    if (-not (Test-Path -LiteralPath $RuntimeRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null
    }
    $pilotRoot = Join-Path $RuntimeRoot 'pilot'
    $decisionPath = Join-Path $pilotRoot 'pilot_decision.json'
    if (Test-Path -LiteralPath $decisionPath -PathType Leaf) {
        $existingDecision = Read-JsonFile $decisionPath
        if ([int]$existingDecision.selected_worker_count -in 1, 2) {
            return $existingDecision
        }
        throw "An existing failed pilot decision is preserved at $decisionPath"
    }
    if (Test-Path -LiteralPath $pilotRoot -PathType Container) {
        $existingPilotItems = @(Get-ChildItem -LiteralPath $pilotRoot -Force)
        if ($existingPilotItems.Count -gt 0) {
            throw "An incomplete pilot root is preserved and must be archived before retry: $pilotRoot"
        }
    } else {
        New-Item -ItemType Directory -Path $pilotRoot -Force | Out-Null
    }

    Write-PilotProgress $pilotRoot 'GATE0_FORMAL_PREFLIGHT_RUNNING' 'formal frozen identity preflight'
    $repoLiteral = ConvertTo-MatlabLiteral $RepoDir
    $pilotLiteral = ConvertTo-MatlabLiteral $pilotRoot
    $toolLiteral = ConvertTo-MatlabLiteral $MatlabToolDir
    $gate0Expression = "addpath('$toolLiteral');" +
        "stage8_1b_formal_preflight('$repoLiteral','$pilotLiteral');"
    Invoke-MatlabBatch $gate0Expression (Join-Path $pilotRoot 'gate0.log')

    $gate1Root = Join-Path $pilotRoot 'gate1'
    New-Item -ItemType Directory -Path $gate1Root -Force | Out-Null
    Write-PilotProgress $pilotRoot 'GATE1_REFERENCE_RUNNING' 'reference runner versus external evaluator'
    $gate1Literal = ConvertTo-MatlabLiteral $gate1Root
    $gate1Expression = "addpath('$toolLiteral');" +
        "stage8_1b_pilot_gate1('$repoLiteral','$gate1Literal');"
    Invoke-MatlabBatch $gate1Expression (Join-Path $gate1Root 'gate1.log')
    $gate1 = Read-JsonFile (Join-Path $gate1Root 'gate1_result.json')
    if (-not [bool]$gate1.gate1_pass) {
        throw 'Gate 1 failed; the protocol requires STOP_AND_FIX_TOOL.'
    }

    $singleRoot = Join-Path $pilotRoot 'gate2a_single_uninterrupted'
    $resumedRoot = Join-Path $pilotRoot 'gate2a_single_resumed'
    $shardedRoot = Join-Path $pilotRoot 'gate2b_two_worker_resumed'
    foreach ($root in @($singleRoot, $resumedRoot, $shardedRoot)) {
        if (Test-Path -LiteralPath $root) {
            throw "Pilot root already exists and will not be overwritten: $root"
        }
    }
    Write-PilotProgress $pilotRoot 'GATE2A_SINGLE_RESUME_RUNNING' 'initializing isolated pilot roots'
    Invoke-PilotRootInit $singleRoot 1 (Join-Path $pilotRoot 'gate2a_single_init.log')
    Invoke-PilotRootInit $resumedRoot 1 (Join-Path $pilotRoot 'gate2a_resumed_init.log')
    Invoke-PilotRootInit $shardedRoot 2 (Join-Path $pilotRoot 'gate2b_sharded_init.log')

    $singleProcess = Start-Worker $singleRoot 1 'uninterrupted'
    $singleMetrics = Wait-WorkerProcesses @($singleProcess) $singleRoot
    if (@($singleMetrics.ExitCodes | Where-Object { $_ -ne 0 }).Count -ne 0) {
        throw 'Gate 2A uninterrupted worker failed.'
    }

    $pauseProcess = Start-Worker $resumedRoot 1 'before_pause'
    $pauseMetrics = Wait-WorkerProcesses @($pauseProcess) $resumedRoot 10
    $pauseCount = @(Get-ChildItem -LiteralPath (Join-Path $resumedRoot 'checkpoints') `
        -Filter '*.mat' -File).Count
    if (-not $pauseMetrics.PauseCreated -or $pauseCount -lt 10 -or $pauseCount -ge 60) {
        throw "Gate 2A did not reach a real safe pause boundary (count=$pauseCount)."
    }
    if (-not (Test-PilotSafePause $resumedRoot 1)) {
        throw 'Gate 2A workers did not reach PAUSED_SAFE with zero tmp/lock/process state.'
    }
    Write-JsonAtomic -Path (Join-Path $pilotRoot 'gate2a_pause_audit.json') `
        -Value ([ordered]@{ safe_to_shutdown = $true; active_worker_count = 0;
            tmp_checkpoint_count = 0; current_trial_lock_count = 0;
            valid_checkpoint_count = $pauseCount; recorded_utc = Get-UtcNowText })
    $resumeIdentity = Get-CheckpointIdentity $resumedRoot
    $resumeIdentity | Export-Csv -LiteralPath `
        (Join-Path $pilotRoot 'gate2a_pre_resume_file_identity.csv') `
        -NoTypeInformation
    Archive-PauseRequest $resumedRoot 'gate2a'
    $resumeProcess = Start-Worker $resumedRoot 1 'after_resume'
    $resumeMetrics = Wait-WorkerProcesses @($resumeProcess) $resumedRoot
    if (@($resumeMetrics.ExitCodes | Where-Object { $_ -ne 0 }).Count -ne 0) {
        throw 'Gate 2A resumed worker failed.'
    }
    $resumeIdentityPass = Test-IdentityUnchanged $resumeIdentity $resumedRoot
    $gate2aResultPath = Join-Path $pilotRoot 'gate2a_result.json'
    $singleLiteral = ConvertTo-MatlabLiteral $singleRoot
    $resumedLiteral = ConvertTo-MatlabLiteral $resumedRoot
    $gate2aLiteral = ConvertTo-MatlabLiteral $gate2aResultPath
    $gate2aExpression = "addpath('$toolLiteral');" +
        "stage8_1b_compare_runtime_roots('$repoLiteral','$singleLiteral'," +
        "'$resumedLiteral','$gate2aLiteral','GATE2A');"
    Invoke-MatlabBatch $gate2aExpression (Join-Path $pilotRoot 'gate2a_compare.log')
    $gate2a = Read-JsonFile $gate2aResultPath
    if (-not [bool]$gate2a.pass -or -not $resumeIdentityPass) {
        throw 'Gate 2A failed; the protocol requires STOP_AND_FIX_RECOVERY.'
    }

    Write-PilotProgress $pilotRoot 'GATE2B_PARALLEL_RUNNING' 'two odd/even workers with pause and resume'
    $parallelBefore = @(
        (Start-Worker $shardedRoot 1 'before_pause'),
        (Start-Worker $shardedRoot 2 'before_pause'))
    $parallelMetrics1 = Wait-WorkerProcesses $parallelBefore $shardedRoot 10
    $gate2bResultPath = Join-Path $pilotRoot 'gate2b_result.json'
    $parallelCrashed = @($parallelMetrics1.ExitCodes | Where-Object {
        $_ -ne 0
    }).Count -ne 0
    $parallelMetrics2 = [pscustomobject]@{
        WallSec = 0.0
        PeakPrivateBytes = 0.0
        PeakPrivateBytesByWorker = @(0.0, 0.0)
        PeakTotalMemoryUtilization = 0.0
        MinimumAvailablePhysicalBytes =
            [double]$parallelMetrics1.MinimumAvailablePhysicalBytes
        SustainedPagefileThrashing = $false
        ExitCodes = @()
        PauseCreated = $false
    }
    if (-not $parallelCrashed) {
        $parallelPauseCount = @(Get-ChildItem -LiteralPath `
            (Join-Path $shardedRoot 'checkpoints') -Filter '*.mat' -File).Count
        if (-not $parallelMetrics1.PauseCreated -or $parallelPauseCount -lt 10 -or
                $parallelPauseCount -ge 60) {
            throw "Gate 2B did not reach a real safe pause boundary (count=$parallelPauseCount)."
        }
        if (-not (Test-PilotSafePause $shardedRoot 2)) {
            throw 'Gate 2B workers did not reach PAUSED_SAFE with zero tmp/lock/process state.'
        }
        Write-JsonAtomic -Path (Join-Path $pilotRoot 'gate2b_pause_audit.json') `
            -Value ([ordered]@{ safe_to_shutdown = $true; active_worker_count = 0;
                tmp_checkpoint_count = 0; current_trial_lock_count = 0;
                valid_checkpoint_count = $parallelPauseCount; recorded_utc = Get-UtcNowText })
        Archive-PauseRequest $shardedRoot 'gate2b'
        $parallelAfter = @(
            (Start-Worker $shardedRoot 1 'after_resume'),
            (Start-Worker $shardedRoot 2 'after_resume'))
        $parallelMetrics2 = Wait-WorkerProcesses $parallelAfter $shardedRoot
        $parallelCrashed = @($parallelMetrics2.ExitCodes | Where-Object {
            $_ -ne 0
        }).Count -ne 0
    }
    if ($parallelCrashed) {
        Write-JsonAtomic -Path $gate2bResultPath -Value ([ordered]@{
            gate_name = 'GATE2B'
            pass = $false
            checkpoint_hash_equality = $false
            baseline_row_hash = [string]$gate2a.baseline_row_hash
            candidate_row_hash = ''
            row_equality = $false
            lambda_num2hex_equality = $false
            state_equality = $false
            separation_status_equality = $false
            element_trial_hash_equality = $false
            summary_gate_paired_equality = $false
            common_trial_count = @(Get-ChildItem -LiteralPath `
                (Join-Path $shardedRoot 'checkpoints') -Filter '*.mat' -File).Count
            row_count = 0
            separation_trigger_count = 0
            last_error = 'TWO_WORKER_PROCESS_CRASH_OR_OOM_RESOURCE_FALLBACK'
        })
    } else {
        $shardedLiteral = ConvertTo-MatlabLiteral $shardedRoot
        $gate2bLiteral = ConvertTo-MatlabLiteral $gate2bResultPath
        $gate2bExpression = "addpath('$toolLiteral');" +
            "stage8_1b_compare_runtime_roots('$repoLiteral','$singleLiteral'," +
            "'$shardedLiteral','$gate2bLiteral','GATE2B');"
        Invoke-MatlabBatch $gate2bExpression (Join-Path $pilotRoot 'gate2b_compare.log')
    }

    if ([bool]$gate1.forced_separation_fixture_required) {
        Write-PilotProgress $pilotRoot 'GATE2B_PARALLEL_RUNNING' 'forced Bsep=199 coverage fixture'
        $fixtureHashes = @()
        foreach ($label in @('uninterrupted', 'resumed', 'sharded')) {
            $fixturePath = Join-Path $pilotRoot "forced_separation_$label.mat"
            $fixtureLiteral = ConvertTo-MatlabLiteral $fixturePath
            $fixtureExpression = "addpath('$toolLiteral');" +
                "stage8_1b_forced_separation_fixture('$repoLiteral','$fixtureLiteral');"
            Invoke-MatlabBatch $fixtureExpression `
                (Join-Path $pilotRoot "forced_separation_$label.log")
            $fixtureHashes += Read-JsonFile "$fixturePath.json"
        }
        $fixturePass = @($fixtureHashes | Select-Object -ExpandProperty row_hash -Unique).Count -eq 1
        $fixturePass = $fixturePass -and
            (@($fixtureHashes | ForEach-Object {
                ($_.lambda_hex -join '|') + ':' + ($_.state -join '|') + ':' +
                ($_.separation_status -join '|')
            } | Select-Object -Unique).Count -eq 1)
        Write-JsonAtomic -Path (Join-Path $pilotRoot 'forced_separation_result.json') `
            -Value ([ordered]@{ pass = $fixturePass; Bsep = 199; formal_substream_count = 199 })
    }

    $singleWorkerActive = Get-CheckpointActiveSeconds $singleRoot 1
    $twoWorkerWall = Get-CheckpointActiveSeconds $shardedRoot 2
    $speedup = if ($twoWorkerWall -gt 0) {
        $singleWorkerActive / $twoWorkerWall
    } else { 0.0 }
    $peakPrivate = (@($singleMetrics.PeakPrivateBytes,
        $pauseMetrics.PeakPrivateBytes, $resumeMetrics.PeakPrivateBytes,
        $parallelMetrics1.PeakPrivateBytes, $parallelMetrics2.PeakPrivateBytes) |
        Measure-Object -Maximum).Maximum
    $parallelPeakByWorker = [ordered]@{}
    for ($workerIndex = 0; $workerIndex -lt 2; $workerIndex++) {
        $beforePeaks = @($parallelMetrics1.PeakPrivateBytesByWorker)
        $afterPeaks = @($parallelMetrics2.PeakPrivateBytesByWorker)
        $workerPeaks = @()
        if ($workerIndex -lt $beforePeaks.Count) {
            $workerPeaks += [double]$beforePeaks[$workerIndex]
        }
        if ($workerIndex -lt $afterPeaks.Count) {
            $workerPeaks += [double]$afterPeaks[$workerIndex]
        }
        $parallelPeakByWorker["worker_$('{0:D2}' -f ($workerIndex + 1))"] =
            if ($workerPeaks.Count -gt 0) {
                [double](($workerPeaks | Measure-Object -Maximum).Maximum)
            } else { 0.0 }
    }
    $peakUtilization = (@($singleMetrics.PeakTotalMemoryUtilization,
        $pauseMetrics.PeakTotalMemoryUtilization,
        $resumeMetrics.PeakTotalMemoryUtilization,
        $parallelMetrics1.PeakTotalMemoryUtilization,
        $parallelMetrics2.PeakTotalMemoryUtilization) |
        Measure-Object -Maximum).Maximum
    $minimumAvailable = (@($singleMetrics.MinimumAvailablePhysicalBytes,
        $pauseMetrics.MinimumAvailablePhysicalBytes,
        $resumeMetrics.MinimumAvailablePhysicalBytes,
        $parallelMetrics1.MinimumAvailablePhysicalBytes,
        $parallelMetrics2.MinimumAvailablePhysicalBytes) |
        Measure-Object -Minimum).Minimum
    $workerCrash = @($parallelMetrics1.ExitCodes + $parallelMetrics2.ExitCodes |
        Where-Object { $_ -ne 0 }).Count -ne 0
    $thrashing = [bool]$parallelMetrics1.SustainedPagefileThrashing -or
        [bool]$parallelMetrics2.SustainedPagefileThrashing
    $resourceReasons = @()
    if ($speedup -lt 1.15) { $resourceReasons += 'SPEEDUP_BELOW_1_15' }
    if ([double]$peakUtilization -gt 0.85) { $resourceReasons += 'MEMORY_UTILIZATION_ABOVE_85_PERCENT' }
    if ([double]$minimumAvailable -lt 2GB) { $resourceReasons += 'AVAILABLE_MEMORY_BELOW_2_GIB' }
    if ($thrashing) { $resourceReasons += 'SUSTAINED_PAGEFILE_THRASHING' }
    if ($workerCrash) { $resourceReasons += 'WORKER_CRASH_OR_OOM' }
    $resourceFailureReason = if ($resourceReasons.Count -eq 0) {
        'NONE'
    } else { $resourceReasons -join '+' }
    Write-JsonAtomic -Path (Join-Path $pilotRoot 'pilot_resources.json') `
        -Value ([ordered]@{
            single_worker_wall_sec = $singleWorkerActive
            two_worker_active_wall_sec = $twoWorkerWall
            single_worker_process_wall_sec = $singleMetrics.WallSec
            two_worker_process_wall_sec = $parallelMetrics1.WallSec + $parallelMetrics2.WallSec
            speedup = $speedup
            peak_private_memory_bytes = [double]$peakPrivate
            peak_private_memory_bytes_by_worker = $parallelPeakByWorker
            peak_total_memory_utilization = [double]$peakUtilization
            minimum_available_physical_bytes = [double]$minimumAvailable
            sustained_pagefile_thrashing = $thrashing
            worker_crash_or_oom = $workerCrash
            resume_file_identity_pass = $resumeIdentityPass
            resource_failure_reason = $resourceFailureReason
            recorded_utc = Get-UtcNowText
        })
    $pilotExpression = "addpath('$toolLiteral');" +
        "stage8_1b_sharded_pilot('$pilotLiteral');"
    Invoke-MatlabBatch $pilotExpression (Join-Path $pilotRoot 'pilot_decision.log')
    $decision = Read-JsonFile $decisionPath
    if ([int]$decision.selected_worker_count -notin 1, 2) {
        throw "Pilot hard-stopped with decision $($decision.pilot_decision)."
    }
    Write-PilotProgress $pilotRoot $decision.pilot_decision 'pilot decision complete'
    return $decision
}

function Get-Protocol {
    $protocolPath = Join-Path $RuntimeRoot 'protocol.json'
    $protocol = Read-JsonFile $protocolPath
    if ($protocol.protocol_version -ne $ProtocolVersion -or
            $protocol.execution_authorization -ne $Authorization) {
        throw 'Runtime protocol version or authorization is invalid.'
    }
    return $protocol
}

function Invoke-MatlabRuntimeAudit {
    param([string]$Label)
    $repoLiteral = ConvertTo-MatlabLiteral $RepoDir
    $rootLiteral = ConvertTo-MatlabLiteral $RuntimeRoot
    $toolLiteral = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$toolLiteral');" +
        "s=stage8_1b_build_status('$repoLiteral','$rootLiteral');" +
        "assert(s.invalid_checkpoint_count==0);assert(s.tmp_checkpoint_count==0);"
    Invoke-MatlabBatch $expression (Join-Path $RuntimeRoot "logs\${Label}.log")
}

function Archive-StaleRuntimeWrites {
    $active = Get-MatchingWorkerProcesses -Root $RuntimeRoot
    if ($active.Count -ne 0) {
        throw 'Cannot archive stale writes while protocol workers are active.'
    }
    $incomplete = Join-Path $RuntimeRoot 'incomplete'
    if (-not (Test-Path -LiteralPath $incomplete -PathType Container)) {
        New-Item -ItemType Directory -Path $incomplete -Force | Out-Null
    }
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    foreach ($item in @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'tmp') `
            -Filter '*.tmp' -File -ErrorAction SilentlyContinue)) {
        Move-Item -LiteralPath $item.FullName -Destination `
            (Join-Path $incomplete "$($item.Name).resume_$stamp")
    }
    foreach ($item in @(Get-ChildItem -LiteralPath `
            (Join-Path $RuntimeRoot 'checkpoints') -Filter '*.tmp' -File `
            -ErrorAction SilentlyContinue)) {
        Move-Item -LiteralPath $item.FullName -Destination `
            (Join-Path $incomplete "$($item.Name).resume_$stamp")
    }
    foreach ($item in @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'workers') `
            -Filter '*.current.lock' -File -ErrorAction SilentlyContinue)) {
        Move-Item -LiteralPath $item.FullName -Destination `
            (Join-Path $incomplete "$($item.Name).resume_$stamp")
    }
}

function Start-SelectedWorkers {
    param([string]$Label)
    $protocol = Get-Protocol
    $started = @()
    for ($workerId = 1; $workerId -le [int]$protocol.selected_worker_count; $workerId++) {
        $pidPath = Join-Path $RuntimeRoot "workers\worker_$('{0:D2}' -f $workerId).pid"
        $alreadyActive = $false
        if (Test-Path -LiteralPath $pidPath -PathType Leaf) {
            $workerPidText = (Get-Content -LiteralPath $pidPath -Raw).Trim()
            if ($workerPidText -match '^\d+$') {
                $workerProcess = Get-CimInstance Win32_Process `
                    -Filter "ProcessId=$workerPidText" `
                    -ErrorAction SilentlyContinue
                if ($null -ne $workerProcess -and
                        $workerProcess.CommandLine -like "*$RuntimeRoot*") {
                    $alreadyActive = $true
                }
            }
        }
        if (-not $alreadyActive) {
            $started += Start-Worker $RuntimeRoot $workerId $Label
        }
    }
    return $started
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

function Get-AttemptActiveWallSeconds {
    param([string]$Root)
    $intervals = @()
    foreach ($attemptPath in @(Get-ChildItem -LiteralPath (Join-Path $Root 'workers') `
            -Filter 'attempt_*.json' -File -ErrorAction SilentlyContinue)) {
        try {
            $attempt = Read-JsonFile $attemptPath.FullName
            $endValue = $null
            if ([string]$attempt.ended_utc -ne '') {
                $endValue = [DateTimeOffset]::Parse([string]$attempt.ended_utc)
            } else {
                $attemptProcess = Get-CimInstance Win32_Process `
                    -Filter "ProcessId=$([int]$attempt.pid)" `
                    -ErrorAction SilentlyContinue
                if ($null -eq $attemptProcess -or
                        $attemptProcess.CommandLine -notlike "*$Root*") { continue }
                $endValue = [DateTimeOffset]::UtcNow
            }
            $intervals += [pscustomobject]@{
                Start = [DateTimeOffset]::Parse([string]$attempt.started_utc)
                End = $endValue
            }
        } catch { }
    }
    if ($intervals.Count -eq 0) { return 0.0 }
    $ordered = @($intervals | Sort-Object Start)
    $currentStart = $ordered[0].Start
    $currentEnd = $ordered[0].End
    $total = 0.0
    for ($index = 1; $index -lt $ordered.Count; $index++) {
        if ($ordered[$index].Start -le $currentEnd) {
            if ($ordered[$index].End -gt $currentEnd) {
                $currentEnd = $ordered[$index].End
            }
        } else {
            $total += ($currentEnd - $currentStart).TotalSeconds
            $currentStart = $ordered[$index].Start
            $currentEnd = $ordered[$index].End
        }
    }
    $total += ($currentEnd - $currentStart).TotalSeconds
    return $total
}

function Get-CheckpointAuditSnapshot {
    param([object]$Protocol)
    $checkpointRoot = Join-Path $RuntimeRoot 'checkpoints'
    $valid = New-Object System.Collections.Generic.List[object]
    $invalid = New-Object System.Collections.Generic.List[object]
    $stratumIds = @($Protocol.stratum_ids | ForEach-Object { [string]$_ })
    $matFiles = @(Get-ChildItem -LiteralPath $checkpointRoot -Filter '*.mat' `
        -File -ErrorAction SilentlyContinue)
    foreach ($file in $matFiles) {
        $commonId = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $reason = ''
        $stratumId = ''
        $trialIndex = 0
        $globalIndex = 0
        try {
            $match = [regex]::Match($commonId, '^(?<stratum>.+)_T(?<trial>\d{4})$')
            if (-not $match.Success) { throw 'checkpoint filename is not a common-trial ID' }
            $stratumId = $match.Groups['stratum'].Value
            $trialIndex = [int]$match.Groups['trial'].Value
            $stratumIndex = -1
            for ($index = 0; $index -lt $stratumIds.Count; $index++) {
                if ($stratumIds[$index] -eq $stratumId) {
                    $stratumIndex = $index
                    break
                }
            }
            if ($stratumIndex -lt 0 -or $trialIndex -lt 1 -or
                    $trialIndex -gt [int]$Protocol.trials_per_stratum) {
                throw 'checkpoint filename is outside the immutable registry'
            }
            $globalIndex = $stratumIndex * [int]$Protocol.trials_per_stratum +
                $trialIndex
            $auditPath = "$($file.FullName).audit.json"
            $audit = Read-JsonFile $auditPath
            $required = @('protocol_version', 'checkpoint_contract_version',
                'protocol_runner_commit', 'common_trial_id',
                'global_common_trial_index', 'content_hash',
                'checkpoint_file_name', 'checkpoint_file_sha256',
                'checkpoint_byte_count', 'validation_status')
            foreach ($field in $required) {
                if ($audit.PSObject.Properties.Name -notcontains $field) {
                    throw "checkpoint audit is missing $field"
                }
            }
            if ([string]$audit.protocol_version -ne [string]$Protocol.protocol_version -or
                    [string]$audit.checkpoint_contract_version -ne
                    [string]$Protocol.checkpoint_contract_version -or
                    [string]$audit.protocol_runner_commit -ne
                    [string]$Protocol.protocol_runner_commit -or
                    [string]$audit.common_trial_id -ne $commonId -or
                    [int]$audit.global_common_trial_index -ne $globalIndex -or
                    [string]$audit.checkpoint_file_name -ne $file.Name -or
                    [long]$audit.checkpoint_byte_count -ne [long]$file.Length -or
                    [string]$audit.validation_status -ne 'VALIDATED_COMPLETE_PASS' -or
                    [string]$audit.content_hash -notmatch '^[0-9a-fA-F]{64}$') {
                throw 'checkpoint audit identity or size differs from the runtime protocol'
            }
            $actualSha = (Get-FileHash -Algorithm SHA256 `
                -LiteralPath $file.FullName).Hash.ToLowerInvariant()
            if ($actualSha -ne
                    ([string]$audit.checkpoint_file_sha256).ToLowerInvariant()) {
                throw 'checkpoint byte hash differs from its validation audit'
            }
            $valid.Add([pscustomobject]@{
                Name = $file.Name
                CommonTrialId = $commonId
                StratumId = $stratumId
                TrialIndex = $trialIndex
                GlobalIndex = $globalIndex
                FullName = $file.FullName
                LastWriteTimeUtc = $file.LastWriteTimeUtc
                ContentHash = [string]$audit.content_hash
            })
        } catch {
            $reason = $_.Exception.Message
            $invalid.Add([pscustomobject]@{
                Name = $file.Name
                CommonTrialId = $commonId
                Reason = $reason
            })
        }
    }
    foreach ($auditFile in @(Get-ChildItem -LiteralPath $checkpointRoot `
            -Filter '*.mat.audit.json' -File -ErrorAction SilentlyContinue)) {
        $matPath = $auditFile.FullName.Substring(
            0, $auditFile.FullName.Length - '.audit.json'.Length)
        if (-not (Test-Path -LiteralPath $matPath -PathType Leaf)) {
            $invalid.Add([pscustomobject]@{
                Name = $auditFile.Name
                CommonTrialId = ''
                Reason = 'orphan checkpoint validation audit'
            })
        }
    }
    return [pscustomobject]@{
        Valid = $valid.ToArray()
        Invalid = $invalid.ToArray()
        MatFileCount = $matFiles.Count
    }
}

function Get-StatusSnapshot {
    $protocolPath = Join-Path $RuntimeRoot 'protocol.json'
    if (-not (Test-Path -LiteralPath $protocolPath -PathType Leaf)) {
        return $null
    }
    $protocol = Get-Protocol
    $statusRoot = Join-Path $RuntimeRoot 'status'
    $logsRoot = Join-Path $RuntimeRoot 'logs'
    foreach ($directory in @($statusRoot, $logsRoot)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
    }
    $prior = $null
    $latestJsonPath = Join-Path $statusRoot 'latest_status.json'
    if (Test-Path -LiteralPath $latestJsonPath -PathType Leaf) {
        try { $prior = Read-JsonFile $latestJsonPath } catch { $prior = $null }
    }
    $now = [DateTimeOffset]::UtcNow
    $workerViews = @()
    $activeCount = 0
    $completedPerWorker = [ordered]@{}
    $lastError = ''
    for ($workerId = 1; $workerId -le [int]$protocol.selected_worker_count; $workerId++) {
        $statusPath = Join-Path $RuntimeRoot "workers\worker_$('{0:D2}' -f $workerId)_status.json"
        $workerStatus = $null
        if (Test-Path -LiteralPath $statusPath -PathType Leaf) {
            try { $workerStatus = Read-JsonFile $statusPath } catch { $workerStatus = $null }
        }
        $workerPidValue = $null
        $pidPath = Join-Path $RuntimeRoot "workers\worker_$('{0:D2}' -f $workerId).pid"
        if (Test-Path -LiteralPath $pidPath -PathType Leaf) {
            $workerPidText = (Get-Content -LiteralPath $pidPath -Raw).Trim()
            if ($workerPidText -match '^\d+$') { $workerPidValue = [int]$workerPidText }
        }
        $responsive = $false
        $cpuSec = 0.0
        $privateBytes = 0.0
        if ($null -ne $workerPidValue) {
            $workerProcess = Get-CimInstance Win32_Process `
                -Filter "ProcessId=$workerPidValue" `
                -ErrorAction SilentlyContinue
            if ($null -ne $workerProcess -and
                    $workerProcess.CommandLine -like "*$RuntimeRoot*") {
                $responsive = $true
                $activeCount++
                $cpuSec = ([double]$workerProcess.KernelModeTime +
                    [double]$workerProcess.UserModeTime) / 10000000.0
                $privateBytes = [double]$workerProcess.PrivatePageCount
            }
        }
        $priorCpu = 0.0
        if ($null -ne $prior -and $null -ne $prior.workers) {
            $priorWorker = @($prior.workers | Where-Object {
                [int]$_.worker_id -eq $workerId })
            if ($priorWorker.Count -eq 1) { $priorCpu = [double]$priorWorker[0].cpu_sec }
        }
        $currentId = ''
        $currentStratum = ''
        $trialStarted = ''
        $heartbeat = ''
        $workerState = 'NOT_STARTED'
        $completedWorker = 0
        if ($null -ne $workerStatus) {
            $currentId = [string]$workerStatus.current_common_trial_id
            $currentStratum = [string]$workerStatus.current_stratum_id
            $trialStarted = [string]$workerStatus.current_trial_started_utc
            $heartbeat = [string]$workerStatus.heartbeat_utc
            $workerState = [string]$workerStatus.worker_state
            $completedWorker = [int]$workerStatus.completed_common_trial_count
            if ([string]$workerStatus.last_error -ne '' -and $lastError -eq '') {
                $lastError = [string]$workerStatus.last_error
            }
        }
        $elapsed = 0.0
        if ($trialStarted -ne '') {
            try { $elapsed = ($now - [DateTimeOffset]::Parse($trialStarted)).TotalSeconds } catch { $elapsed = 0.0 }
        }
        $completedPerWorker["worker_$('{0:D2}' -f $workerId)"] = $completedWorker
        $workerViews += [pscustomobject]@{
            worker_id = $workerId
            pid = $workerPidValue
            responsive = $responsive
            cpu_sec = $cpuSec
            cpu_time_delta_sec = [Math]::Max(0.0, $cpuSec - $priorCpu)
            private_memory_bytes = $privateBytes
            worker_state = $workerState
            current_common_trial_id = $currentId
            current_stratum_id = $currentStratum
            current_trial_started_utc = $trialStarted
            current_trial_elapsed_sec = $elapsed
            heartbeat_utc = $heartbeat
        }
    }

    $checkpointAudit = Get-CheckpointAuditSnapshot -Protocol $protocol
    $validCheckpoints = @($checkpointAudit.Valid)
    $invalidCheckpoints = @($checkpointAudit.Invalid)
    $completed = $validCheckpoints.Count
    $remaining = [int]$protocol.common_trial_count - $completed
    $tmpCount = @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'tmp') `
        -Filter '*.tmp' -File -ErrorAction SilentlyContinue).Count +
        @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'checkpoints') `
        -Filter '*.tmp' -File -ErrorAction SilentlyContinue).Count
    $lockCount = @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'workers') `
        -Filter '*.current.lock' -File -ErrorAction SilentlyContinue).Count
    $invalidCount = $invalidCheckpoints.Count
    if ($invalidCount -gt 0 -and $lastError -eq '') {
        $lastError = "CHECKPOINT_AUDIT_FAILED: $($invalidCheckpoints[0].Name): " +
            [string]$invalidCheckpoints[0].Reason
    }
    $histories = @()
    foreach ($historyPath in @(Get-ChildItem -LiteralPath $logsRoot `
            -Filter 'worker_*_checkpoint_history.csv' -File -ErrorAction SilentlyContinue)) {
        try { $histories += @(Import-Csv -LiteralPath $historyPath.FullName) } catch { }
    }
    $validIdLookup = @{}
    foreach ($checkpoint in $validCheckpoints) {
        $validIdLookup[[string]$checkpoint.CommonTrialId] = $true
    }
    $histories = @($histories | Where-Object {
        $validIdLookup.ContainsKey([string]$_.common_trial_id)
    })
    $stratumIds = @($protocol.stratum_ids)
    $perStratumCompleted = [ordered]@{}
    $perStratumRemaining = [ordered]@{}
    $runtimeByStratum = @{}
    $runtimeStatsByStratum = [ordered]@{}
    $separationRateByStratum = [ordered]@{}
    foreach ($stratumId in $stratumIds) {
        $selectedCheckpoints = @($validCheckpoints | Where-Object {
            $_.StratumId -eq $stratumId
        })
        $selected = @($histories | Where-Object { $_.stratum_id -eq $stratumId })
        $perStratumCompleted[$stratumId] = $selectedCheckpoints.Count
        $perStratumRemaining[$stratumId] =
            [int]$protocol.trials_per_stratum - $selectedCheckpoints.Count
        $runtimeByStratum[$stratumId] = @($selected | ForEach-Object {
            [double]$_.runtime_sec })
        $stratumRuntimes = [double[]]$runtimeByStratum[$stratumId]
        $stratumMean = if ($stratumRuntimes.Count -gt 0) {
            [double](($stratumRuntimes | Measure-Object -Average).Average)
        } else { $null }
        $runtimeStatsByStratum[$stratumId] = [ordered]@{
            checkpoint_count = $selected.Count
            mean_sec = $stratumMean
            p50_sec = Get-Percentile $stratumRuntimes 0.50
            p75_sec = Get-Percentile $stratumRuntimes 0.75
            p90_sec = Get-Percentile $stratumRuntimes 0.90
        }
        $triggerRows = if ($selected.Count -gt 0) {
            [double](($selected | Measure-Object -Property separation_trigger_rows -Sum).Sum)
        } else { 0.0 }
        $separationRateByStratum[$stratumId] = if ($selected.Count -gt 0) {
            $triggerRows / (2.0 * $selected.Count)
        } else { $null }
    }
    if ([int]$protocol.selected_worker_count -eq 1) {
        $completedPerWorker['worker_01'] = $completed
    } else {
        $completedPerWorker['worker_01'] = @($validCheckpoints | Where-Object {
            ([int]$_.GlobalIndex % 2) -eq 1
        }).Count
        $completedPerWorker['worker_02'] = @($validCheckpoints | Where-Object {
            ([int]$_.GlobalIndex % 2) -eq 0
        }).Count
    }
    $stateCounts = [ordered]@{
        K1 = 0; K2_RESOLVED = 0; K2_UNRESOLVED = 0
        SEARCH_NOT_CONVERGED = 0; NUMERIC_RANK_DEFICIENT = 0
        OUT_OF_LOCAL_CELL = 0
    }
    foreach ($history in $histories) {
        foreach ($stateName in @([string]$history.primary_state,
                [string]$history.sensitivity_state)) {
            if ($stateCounts.Contains($stateName)) { $stateCounts[$stateName]++ }
        }
    }
    $separationRows = 0
    if ($histories.Count -gt 0) {
        $separationRows = [int](($histories | Measure-Object `
            -Property separation_trigger_rows -Sum).Sum)
    }
    $allRuntimes = @($histories | ForEach-Object { [double]$_.runtime_sec })
    $lastCheckpointUtc = ''
    $minutesSinceLast = $null
    if ($validCheckpoints.Count -gt 0) {
        $lastFile = $validCheckpoints | Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
        $lastCheckpointUtc = $lastFile.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        $minutesSinceLast = ([DateTime]::UtcNow - $lastFile.LastWriteTimeUtc).TotalMinutes
    }
    $throughput15 = @($histories | Where-Object {
        try { [DateTimeOffset]::Parse($_.created_utc) -ge $now.AddMinutes(-15) } catch { $false }
    }).Count * 4.0
    $throughput60 = @($histories | Where-Object {
        try { [DateTimeOffset]::Parse($_.created_utc) -ge $now.AddMinutes(-60) } catch { $false }
    }).Count

    $overallP50 = Get-Percentile $allRuntimes 0.50
    $overallP75 = Get-Percentile $allRuntimes 0.75
    $overallP90 = Get-Percentile $allRuntimes 0.90
    $etaWorkerLow = @(0.0, 0.0)
    $etaWorkerPoint = @(0.0, 0.0)
    $etaWorkerHigh = @(0.0, 0.0)
    for ($stratumIndex = 0; $stratumIndex -lt $stratumIds.Count; $stratumIndex++) {
        $stratumId = [string]$stratumIds[$stratumIndex]
        $values = [double[]]$runtimeByStratum[$stratumId]
        $p50 = Get-Percentile $values 0.50
        $p90 = Get-Percentile $values 0.90
        $mean = if ($values.Count -gt 0) {
            ($values | Measure-Object -Average).Average
        } else { $null }
        if ($null -eq $p50) { $p50 = $overallP50 }
        if ($null -eq $p90) { $p90 = $overallP90 }
        if ($null -eq $mean -and $allRuntimes.Count -gt 0) {
            $mean = ($allRuntimes | Measure-Object -Average).Average
        }
        if ($null -eq $p50) { continue }
        $completedIds = @($validCheckpoints | Where-Object {
            $_.StratumId -eq $stratumId
        } | Select-Object -ExpandProperty CommonTrialId)
        for ($trialIndex = 1; $trialIndex -le [int]$protocol.trials_per_stratum; $trialIndex++) {
            $trialId = '{0}_T{1:D4}' -f $stratumId, $trialIndex
            if ($completedIds -contains $trialId) { continue }
            $targetWorker = 0
            if ([int]$protocol.selected_worker_count -eq 2) {
                $globalIndex = $stratumIndex * [int]$protocol.trials_per_stratum + $trialIndex
                $targetWorker = if (($globalIndex % 2) -eq 1) { 0 } else { 1 }
            }
            $etaWorkerLow[$targetWorker] += [double]$p50
            $etaWorkerPoint[$targetWorker] += [double]$mean
            $etaWorkerHigh[$targetWorker] += [double]$p90
        }
    }
    $etaLowHours = if ($allRuntimes.Count -eq 0) { $null } else {
        (($etaWorkerLow | Measure-Object -Maximum).Maximum / 3600.0)
    }
    $etaPointHours = if ($allRuntimes.Count -eq 0) { $null } else {
        (($etaWorkerPoint | Measure-Object -Maximum).Maximum / 3600.0)
    }
    $etaHighHours = if ($allRuntimes.Count -eq 0) { $null } else {
        (($etaWorkerHigh | Measure-Object -Maximum).Maximum / 3600.0)
    }
    $etaConfidence = if ($completed -lt 20) { 'LOW' }
        elseif ($completed -lt 200) { 'MEDIUM' } else { 'HIGH' }
    $estimatedFinish = $null
    if ($null -ne $etaPointHours) {
        $estimatedFinish = (Get-Date).AddHours($etaPointHours).ToString('o')
    }

    $pauseRequested = Test-Path -LiteralPath (Join-Path $RuntimeRoot 'control\pause.request')
    foreach ($worker in $workerViews) {
        $terminalWorkerState = [string]$worker.worker_state -in @(
            'COMPLETE', 'PAUSED_SAFE', 'ERROR_STOPPED')
        if ([bool]$worker.responsive -and $terminalWorkerState -and $lastError -eq '') {
            $lastError = "WORKER_STATE_PROCESS_CONTRADICTION: worker_$('{0:D2}' -f $worker.worker_id) " +
                "is $($worker.worker_state) but PID $($worker.pid) is active"
        }
        if (-not [bool]$worker.responsive -and
                [string]$worker.worker_state -in @('STARTING', 'RUNNING') -and
                -not $pauseRequested -and $completed -lt [int]$protocol.common_trial_count -and
                $lastError -eq '') {
            $lastError = "UNEXPECTED_WORKER_EXIT: worker_$('{0:D2}' -f $worker.worker_id) " +
                "is $($worker.worker_state) without an active protocol PID"
        }
    }
    $repoStatus = @(& git -C $RepoDir status --porcelain=v1 --untracked-files=all)
    $gitClean = $LASTEXITCODE -eq 0 -and $repoStatus.Count -eq 0
    $resultFiles = @(Get-ChildItem -LiteralPath (Join-Path $StepRoot 'results') `
        -File -Force -ErrorAction SilentlyContinue)
    $resultsClean = $resultFiles.Count -eq 1 -and $resultFiles[0].Name -eq '.gitkeep'
    $calibrationMatch = $true
    $frozenSnapshotPath = Join-Path $RuntimeRoot 'frozen_calibration_snapshot.csv'
    if (Test-Path -LiteralPath $frozenSnapshotPath -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $frozenSnapshotPath)) {
            $relative = ([string]$row.relative_path).Replace('/', '\')
            $artifactPath = Join-Path $StepRoot $relative
            if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf) -or
                    (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash.ToLowerInvariant() -ne
                    ([string]$row.sha256).ToLowerInvariant()) {
                $calibrationMatch = $false
                break
            }
        }
    } else { $calibrationMatch = $false }
    $finalAudit = Join-Path $RuntimeRoot 'merged\finalization_audit.json'
    $isFormalRuntime = $protocol.PSObject.Properties.Name -contains
        'scientific_formal_run' -and [bool]$protocol.scientific_formal_run
    if ($isFormalRuntime -and -not $gitClean -and $lastError -eq '') {
        $lastError = 'REPOSITORY_STATE_CHANGED: formal runtime requires a clean worktree'
    }
    if ($isFormalRuntime -and -not $calibrationMatch -and $lastError -eq '') {
        $lastError = 'CALIBRATION_SNAPSHOT_CHANGED: frozen artifact bytes no longer match'
    }
    if ($isFormalRuntime -and -not $resultsClean -and
            -not (Test-Path -LiteralPath $finalAudit -PathType Leaf) -and
            $lastError -eq '') {
        $lastError = 'RESULTS_DIRECTORY_CHANGED_BEFORE_FINALIZE'
    }
    $possibleStall = $false
    if ($activeCount -gt 0 -and $null -ne $minutesSinceLast -and
            $null -ne $overallP90) {
        $possibleStall = $minutesSinceLast -gt
            [Math]::Max(30.0, 3.0 * [double]$overallP90 / 60.0)
    }
    $safeToShutdown = $pauseRequested -and $activeCount -eq 0 -and
        $tmpCount -eq 0 -and $lockCount -eq 0 -and $invalidCount -eq 0 -and
        $resultsClean -and $calibrationMatch -and $gitClean -and $lastError -eq ''
    if (Test-Path -LiteralPath $finalAudit -PathType Leaf) {
        $stage = 'FINALIZED_RESULTS_WRITTEN'
    } elseif ($lastError -ne '') {
        $stage = 'ERROR_STOPPED'
    } elseif ($completed -eq [int]$protocol.common_trial_count -and
            $activeCount -eq 0 -and $invalidCount -eq 0 -and
            $tmpCount -eq 0 -and $lockCount -eq 0) {
        $stage = 'COMPLETE_CHECKPOINT_SET_6000'
    } elseif ($safeToShutdown) {
        $stage = 'PAUSED_SAFE_TO_SHUTDOWN'
    } elseif ($pauseRequested) {
        $stage = 'PAUSE_REQUESTED'
    } elseif ($activeCount -gt 0 -and [int]$protocol.selected_worker_count -eq 2) {
        $stage = 'FORMAL_SHARDED_RUNNING'
    } elseif ($activeCount -gt 0) {
        $stage = 'FORMAL_SINGLE_WORKER_RESUMABLE_RUNNING'
    } else {
        $stage = 'PROTOCOL_COMMITTED'
    }
    $summedSuccessfulTrialComputeSec = 0.0
    if ($allRuntimes.Count -gt 0) {
        $summedSuccessfulTrialComputeSec =
            [double](($allRuntimes | Measure-Object -Sum).Sum)
    }
    $status = [ordered]@{
        protocol_version = $protocol.protocol_version
        protocol_runner_commit = $protocol.protocol_runner_commit
        protocol_stage = $stage
        pilot_decision = $protocol.pilot_decision
        selected_execution_mode = $protocol.selected_execution_mode
        selected_worker_count = [int]$protocol.selected_worker_count
        fallback_reason = $protocol.fallback_reason
        safe_to_shutdown = $safeToShutdown
        pause_requested = $pauseRequested
        active_worker_count = $activeCount
        worker_pids = @($workerViews | Select-Object -ExpandProperty pid)
        workers = $workerViews
        completed_common_trials = $completed
        total_common_trials = [int]$protocol.common_trial_count
        remaining_common_trials = $remaining
        completed_rows = 2 * $completed
        total_rows = [int]$protocol.row_count
        completed_per_stratum = $perStratumCompleted
        remaining_per_stratum = $perStratumRemaining
        completed_per_worker = $completedPerWorker
        valid_checkpoint_count = $completed
        checkpoint_file_count = [int]$checkpointAudit.MatFileCount
        tmp_checkpoint_count = $tmpCount
        invalid_checkpoint_count = $invalidCount
        checkpoint_audit_errors = @($invalidCheckpoints | Select-Object Name,
            CommonTrialId, Reason)
        current_trial_lock_count = $lockCount
        separation_trigger_row_count = $separationRows
        state_counts = $stateCounts
        last_checkpoint_utc = $lastCheckpointUtc
        minutes_since_last_checkpoint = $minutesSinceLast
        active_wall_time_sec = Get-AttemptActiveWallSeconds $RuntimeRoot
        summed_successful_trial_compute_sec = $summedSuccessfulTrialComputeSec
        rolling_15_minute_throughput_trials_per_hour = $throughput15
        rolling_60_minute_throughput_trials_per_hour = $throughput60
        rolling_p50_trial_runtime_sec = $overallP50
        rolling_p75_trial_runtime_sec = $overallP75
        rolling_p90_trial_runtime_sec = $overallP90
        rolling_runtime_sec_per_stratum = $runtimeStatsByStratum
        rolling_separation_trigger_row_rate_per_stratum = $separationRateByStratum
        eta_low_active_hours = $etaLowHours
        eta_point_active_hours = $etaPointHours
        eta_high_active_hours = $etaHighHours
        eta_confidence = $etaConfidence
        estimated_finish_if_continuous_local_time = $estimatedFinish
        results_directory_clean = $resultsClean
        calibration_snapshot_match = $calibrationMatch
        git_clean = $gitClean
        possible_stall_warning = $possibleStall
        last_error = $lastError
        status_generated_utc = Get-UtcNowText
    }
    Write-JsonAtomic $latestJsonPath $status
    $progressPercent = if ([int]$protocol.common_trial_count -gt 0) {
        100.0 * $completed / [int]$protocol.common_trial_count
    } else { 0.0 }
    $stratumText = ($stratumIds | ForEach-Object {
        "$_ $($perStratumCompleted[$_])/$([int]$protocol.trials_per_stratum)"
    }) -join ' | '
    $workerText = ($workerViews | ForEach-Object {
        "Worker $('{0:D2}' -f $_.worker_id): PID $($_.pid) | $($_.worker_state) | " +
        "$($_.current_common_trial_id) | elapsed $([Math]::Round($_.current_trial_elapsed_sec,1)) s"
    }) -join [Environment]::NewLine
    $etaText = if ($null -eq $etaPointHours) { 'unavailable' } else {
        ('{0:N2} h [low {1:N2}, high {2:N2}]' -f
            $etaPointHours, $etaLowHours, $etaHighHours)
    }
    $text = @(
        'Stage8.1B K1 Validation Status'
        "Protocol stage : $stage"
        "Pilot decision : $($protocol.pilot_decision)"
        "Execution mode : $($protocol.selected_execution_mode)"
        "Fallback reason: $($protocol.fallback_reason)"
        ('Progress       : {0} / {1} common trials ({2:N2}%)' -f
            $completed, $protocol.common_trial_count, $progressPercent)
        "Rows           : $(2 * $completed) / $($protocol.row_count)"
        "Strata         : $stratumText"
        $workerText
        "Separation rows: $separationRows"
        "Throughput     : $throughput60 trials/hour (60-minute rolling)"
        "ETA active     : $etaText, confidence $etaConfidence"
        "Pause requested: $pauseRequested"
        "Safe shutdown  : $safeToShutdown"
        "Last checkpoint: $lastCheckpointUtc"
        "Possible stall : $possibleStall"
        "Git clean      : $gitClean"
        "Calibration    : $calibrationMatch"
        "Results clean  : $resultsClean"
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText((Join-Path $statusRoot 'latest_status.txt'),
        $text + [Environment]::NewLine, $script:Utf8NoBom)
    $historyPath = Join-Path $logsRoot 'status_history.csv'
    $historyRow = [pscustomobject]@{
        status_generated_utc = $status.status_generated_utc
        protocol_stage = $stage
        completed_common_trials = $completed
        active_worker_count = $activeCount
        throughput_60m = $throughput60
        eta_point_active_hours = $etaPointHours
        eta_high_active_hours = $etaHighHours
        safe_to_shutdown = $safeToShutdown
        possible_stall_warning = $possibleStall
    }
    if (Test-Path -LiteralPath $historyPath -PathType Leaf) {
        $historyRow | Export-Csv -LiteralPath $historyPath -NoTypeInformation -Append
    } else {
        $historyRow | Export-Csv -LiteralPath $historyPath -NoTypeInformation
    }
    return [pscustomobject]$status
}

function Register-StatusTask {
    $scriptPath = $PSCommandPath
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Action Status ' +
        '-RuntimeRoot "{1}" -RepoDir "{2}" -MatlabExe "{3}"'
    $arguments = $arguments -f $scriptPath, $RuntimeRoot, $RepoDir, $MatlabExe
    $taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
        -RepetitionInterval (New-TimeSpan -Minutes 15)
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    Register-ScheduledTask -TaskName $StatusTaskName -Action $taskAction `
        -Trigger $trigger -Settings $settings `
        -Description 'Read-only Stage8.1B K1 validation status snapshot every 15 minutes.' `
        -Force | Out-Null
}

function Unregister-StatusTask {
    $existing = Get-ScheduledTask -TaskName $StatusTaskName -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        Unregister-ScheduledTask -TaskName $StatusTaskName -Confirm:$false
    }
}

function Invoke-Init {
    Assert-NoStage8Matlab
    $pilotDecisionPath = Join-Path $RuntimeRoot 'pilot\pilot_decision.json'
    if (-not (Test-Path -LiteralPath $pilotDecisionPath -PathType Leaf)) {
        throw 'Init requires a completed pilot_decision.json.'
    }
    $repoLiteral = ConvertTo-MatlabLiteral $RepoDir
    $rootLiteral = ConvertTo-MatlabLiteral $RuntimeRoot
    $decisionLiteral = ConvertTo-MatlabLiteral $pilotDecisionPath
    $toolLiteral = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$toolLiteral');" +
        "stage8_1b_initialize_runtime('$repoLiteral','$rootLiteral','$decisionLiteral');"
    Invoke-MatlabBatch $expression (Join-Path $RuntimeRoot 'logs\formal_init.log')
    Register-StatusTask
    return Get-StatusSnapshot
}

function Invoke-Start {
    if (Test-Path -LiteralPath (Join-Path $RuntimeRoot 'control\pause.request')) {
        throw 'Start is blocked by pause.request; use Resume to archive it safely.'
    }
    $protocol = Get-Protocol
    $activeWorkers = (Get-MatchingWorkerProcesses $RuntimeRoot).Count
    $priorAttempts = @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'workers') `
        -Filter 'attempt_*.json' -File -ErrorAction SilentlyContinue).Count
    if ($activeWorkers -eq 0 -and $priorAttempts -gt 0) {
        throw 'Start is initial-only after Init; use Resume for an existing attempt history.'
    }
    if ($activeWorkers -gt 0 -and
            $activeWorkers -lt [int]$protocol.selected_worker_count) {
        throw 'A selected worker is missing; request Pause, then use Resume after all workers exit.'
    }
    if ($activeWorkers -eq 0) {
        Invoke-MatlabRuntimeAudit 'start_preflight'
    }
    $started = @(Start-SelectedWorkers 'formal_start')
    Start-Sleep -Seconds 2
    $status = Get-StatusSnapshot
    return [pscustomobject]@{ StartedProcessIds = @($started | ForEach-Object { $_.Id }); Status = $status }
}

function Invoke-Pause {
    Get-Protocol | Out-Null
    $requestPath = Join-Path $RuntimeRoot 'control\pause.request'
    if (-not (Test-Path -LiteralPath $requestPath -PathType Leaf)) {
        [System.IO.File]::WriteAllText($requestPath,
            "requested_utc=$(Get-UtcNowText)`nrequested_by=MANUAL_POWERSHELL_ACTION`n",
            $script:Utf8NoBom)
    }
    return Get-StatusSnapshot
}

function Invoke-Resume {
    Get-Protocol | Out-Null
    if ((Get-MatchingWorkerProcesses $RuntimeRoot).Count -ne 0) {
        throw 'Resume requires all prior worker processes to be stopped.'
    }
    Archive-StaleRuntimeWrites
    Invoke-MatlabRuntimeAudit 'resume_preflight'
    Archive-PauseRequest $RuntimeRoot 'formal_resume'
    $started = @(Start-SelectedWorkers 'formal_resume')
    Start-Sleep -Seconds 2
    $status = Get-StatusSnapshot
    return [pscustomobject]@{ StartedProcessIds = @($started | ForEach-Object { $_.Id }); Status = $status }
}

function Invoke-ForceStop {
    $protocol = Get-Protocol
    $requestPath = Join-Path $RuntimeRoot 'control\pause.request'
    if (-not (Test-Path -LiteralPath $requestPath -PathType Leaf)) {
        [System.IO.File]::WriteAllText($requestPath,
            "requested_utc=$(Get-UtcNowText)`nrequested_by=MANUAL_FORCE_STOP`n",
            $script:Utf8NoBom)
    }
    $stopped = @()
    for ($workerId = 1; $workerId -le [int]$protocol.selected_worker_count; $workerId++) {
        $pidPath = Join-Path $RuntimeRoot "workers\worker_$('{0:D2}' -f $workerId).pid"
        if (-not (Test-Path -LiteralPath $pidPath -PathType Leaf)) { continue }
        $workerPidText = (Get-Content -LiteralPath $pidPath -Raw).Trim()
        if ($workerPidText -notmatch '^\d+$') { continue }
        $workerProcess = Get-CimInstance Win32_Process `
            -Filter "ProcessId=$workerPidText" `
            -ErrorAction SilentlyContinue
        if ($null -ne $workerProcess -and
                $workerProcess.CommandLine -like "*$RuntimeRoot*" -and
                $workerProcess.CommandLine -match 'stage8_1b_sharded_worker') {
            Stop-Process -Id ([int]$workerPidText) -Force
            $stopped += [int]$workerPidText
        }
    }
    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-MatchingWorkerProcesses $RuntimeRoot).Count -ne 0 -and
            (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
    }
    if ((Get-MatchingWorkerProcesses $RuntimeRoot).Count -ne 0) {
        throw 'Protocol workers did not exit after ForceStop.'
    }
    foreach ($attemptPath in @(Get-ChildItem -LiteralPath `
            (Join-Path $RuntimeRoot 'workers') -Filter 'attempt_*.json' -File `
            -ErrorAction SilentlyContinue)) {
        $attempt = Read-JsonFile $attemptPath.FullName
        if ([string]$attempt.ended_utc -eq '' -and
                $stopped -contains [int]$attempt.pid) {
            $attempt.ended_utc = Get-UtcNowText
            $attempt.completion_status = 'FORCE_STOPPED'
            Write-JsonAtomic $attemptPath.FullName $attempt
        }
    }
    Archive-StaleRuntimeWrites
    Write-JsonAtomic -Path (Join-Path $RuntimeRoot `
        ("incomplete\forced_stop_" + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '.json')) `
        -Value ([ordered]@{
            forced_stop_utc = Get-UtcNowText
            stopped_process_ids = $stopped
            runtime_root = $RuntimeRoot
            completed_checkpoints_preserved = $true
        })
    $status = Get-StatusSnapshot
    return [pscustomobject]@{ StoppedProcessIds = $stopped; Status = $status }
}

function Invoke-Finalize {
    $status = Get-StatusSnapshot
    $protocol = Get-Protocol
    if ($status.completed_common_trials -ne [int]$protocol.common_trial_count -or
            $status.active_worker_count -ne 0 -or $status.tmp_checkpoint_count -ne 0 -or
            $status.current_trial_lock_count -ne 0 -or
            $status.invalid_checkpoint_count -ne 0 -or
            -not $status.git_clean -or -not $status.calibration_snapshot_match -or
            -not $status.results_directory_clean -or [string]$status.last_error -ne '') {
        throw 'Finalize requires a complete, inactive, valid checkpoint set.'
    }
    $repoLiteral = ConvertTo-MatlabLiteral $RepoDir
    $rootLiteral = ConvertTo-MatlabLiteral $RuntimeRoot
    $toolLiteral = ConvertTo-MatlabLiteral $MatlabToolDir
    $expression = "addpath('$toolLiteral');" +
        "stage8_1b_sharded_merge_finalize('$repoLiteral','$rootLiteral');"
    Invoke-MatlabBatch $expression (Join-Path $RuntimeRoot 'logs\merge_finalize.log')
    return Get-StatusSnapshot
}

$matlabActions = @('Pilot', 'Init', 'Start', 'Resume', 'Finalize')
Assert-Paths -RequireMatlab ($Action -in $matlabActions)
switch ($Action) {
    'Pilot' { Invoke-Pilot }
    'Init' { Invoke-Init }
    'Start' { Invoke-Start }
    'Pause' { Invoke-Pause }
    'Resume' { Invoke-Resume }
    'Status' { Get-StatusSnapshot }
    'ForceStop' { Invoke-ForceStop }
    'RegisterStatusTask' { Register-StatusTask; Get-StatusSnapshot }
    'UnregisterStatusTask' { Unregister-StatusTask }
    'Finalize' { Invoke-Finalize }
}
