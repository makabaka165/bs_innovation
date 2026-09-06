[CmdletBinding()]
param(
    [ValidateSet('InstallAndStart','Tick','Status','Test','TestLaunch','TestProbe')][string]$Action='Status',
    [string]$RepoDir='E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8',
    [string]$RuntimeRoot='E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1'
)
$ErrorActionPreference='Stop'
# MATLAB can inherit a PowerShell 7 module path before invoking Windows PowerShell.
if ($PSEdition -eq 'Desktop') {
    $systemModules=Join-Path $PSHOME 'Modules'
    $env:PSModulePath=$systemModules+';'+$env:PSModulePath
    Import-Module (Join-Path $systemModules 'Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1')
}
$TaskName='BSInnovation-Stage8K2-RawTangent-TwoScenarios-L8-V1'
$MatlabExe='E:\MATLABR2022b\bin\matlab.exe'
$StatePath=Join-Path $RuntimeRoot 'controller\controller_state.json'
$Branch='experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1'
if ($Action -eq 'TestProbe') { $StatePath=Join-Path $RuntimeRoot 'tests\process_launch_state.json' }

function Write-JsonAtomic([string]$Filename,$Value) {
    $temporary="$Filename.tmp"
    if (Test-Path -LiteralPath $temporary) { throw "Existing temporary file: $temporary" }
    [IO.File]::WriteAllText($temporary,($Value | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $Filename -Force
}
function Invoke-CheckedGit([string[]]$GitArgs) {
    $value=& git -C $RepoDir @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $GitArgs" }
    return ($value | Out-String).Trim()
}
function Assert-Identity {
    if ([IO.Path]::GetFullPath($RepoDir) -ne 'E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8' -or
        [IO.Path]::GetFullPath($RuntimeRoot) -ne 'E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1') { throw 'Wrong experiment paths.' }
    if ((Invoke-CheckedGit @('branch','--show-current')) -ne $Branch) { throw 'Wrong branch.' }
    foreach ($ref in @('main','origin/main')) {
        if ((Invoke-CheckedGit @('rev-parse',$ref)) -ne '644fc6e0041e400b6500579bba93d49f45e46990') { throw 'Main anchor moved.' }
    }
    if ((Invoke-CheckedGit @('rev-parse','research/stage8-k2-vincent-anchored')) -ne 'a7139204d717923cb89d0d629b67f1b3ab7ae94d') { throw 'Research anchor moved.' }
    foreach ($ref in @('experiment/stage8-k2-raw-tangent-core-native-snr-v1','origin/experiment/stage8-k2-raw-tangent-core-native-snr-v1')) {
        if ((Invoke-CheckedGit @('rev-parse',$ref)) -ne 'f1b13422a91540073ecf417c3b25f5cac552b9d6') { throw 'Source parent moved.' }
    }
    $original=& git -C 'E:\bs_innovation' status --porcelain=v1 --untracked-files=all
    if ($LASTEXITCODE -ne 0 -or @($original).Count) { throw 'Original main worktree is dirty.' }
}
function Get-Decision([string]$State,[bool]$Running,[bool]$Done,[bool]$Launched) {
    if ($State -in @('COMPLETE','HARD_STOPPED')) { return 'NONE' }
    if ($Running) { return 'NONE' }
    switch ($State) {
        'PREPARED' { return 'START_BEAMSPACE' }
        'BEAMSPACE_RUNNING' { if ($Done) { return 'START_ELEMENT' }; return 'RESUME_BEAMSPACE' }
        'ELEMENT_RUNNING' { if ($Done) { return 'READY_TO_FINALIZE' }; return 'RESUME_ELEMENT' }
        'READY_TO_FINALIZE' { return 'START_FINALIZATION' }
        'FINALIZATION_RUNNING' { if ($Done) { return 'READY_FOR_AUDIT' }; if ($Launched) { return 'HARD_STOPPED' }; return 'START_FINALIZATION' }
        'READY_FOR_AUDIT' { return 'START_AUDIT' }
        'AUDIT_RUNNING' { if ($Done) { return 'READY_FOR_GIT_CLOSEOUT' }; if ($Launched) { return 'HARD_STOPPED' }; return 'START_AUDIT' }
        'READY_FOR_GIT_CLOSEOUT' { return 'CLOSEOUT' }
        default { throw "Unknown state: $State" }
    }
}
function Get-MatlabInventory([object[]]$Processes,$State) {
    if (-not $Processes.Count) { return [pscustomobject]@{running=$false;launchers=0;workers=0} }
    if (-not $State.launched -or $State.pid -le 0 -or -not $State.batch_expression -or -not $State.log) {
        throw 'MATLAB exists without a recorded launch identity.'
    }
    $launchers=@($Processes | Where-Object { $_.ExecutablePath -ieq $MatlabExe })
    $workers=@($Processes | Where-Object { $_.ExecutablePath -ieq 'E:\MATLABR2022b\bin\win64\MATLAB.exe' })
    if ($launchers.Count+$workers.Count -ne $Processes.Count) { throw 'Unrelated or unidentified MATLAB/mwpython process detected.' }
    if ($launchers.Count -gt 1 -or $workers.Count -gt 1) { throw 'Multiple MATLAB launchers or compute workers detected.' }
    if (-not ('RTCCommandLine' -as [type])) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class RTCCommandLine {
    [DllImport("shell32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    private static extern IntPtr CommandLineToArgvW(string command, out int count);
    [DllImport("kernel32.dll")]
    private static extern IntPtr LocalFree(IntPtr memory);
    public static string[] Parse(string command) {
        int count;
        IntPtr memory = CommandLineToArgvW(command, out count);
        if (memory == IntPtr.Zero) throw new System.ComponentModel.Win32Exception();
        try {
            string[] args = new string[count];
            for (int i=0; i<count; i++)
                args[i] = Marshal.PtrToStringUni(Marshal.ReadIntPtr(memory, i*IntPtr.Size));
            return args;
        } finally { LocalFree(memory); }
    }
}
'@
    }
    $started=([DateTime]$State.process_start_utc).ToUniversalTime()
    foreach ($process in $Processes) {
        if (-not $process.CommandLine -or -not $process.CreationDate) { throw 'Missing MATLAB command/start identity.' }
        $arguments=[RTCCommandLine]::Parse($process.CommandLine)
        if ($arguments.Count -ne 6 -or $arguments[0] -ine $process.ExecutablePath -or
            $arguments[1] -ine '-singleCompThread' -or $arguments[2] -ine '-batch' -or
            $arguments[3] -cne $State.batch_expression -or $arguments[4] -ine '-logfile' -or
            $arguments[5] -cne $State.log) { throw 'MATLAB command identity mismatch.' }
    }
    if ($launchers.Count) {
        $launcher=$launchers[0]
        if ($launcher.ProcessId -ne $State.pid -or
            [Math]::Abs(($launcher.CreationDate.ToUniversalTime()-$started).TotalSeconds) -gt 0.1) { throw 'MATLAB launcher identity mismatch.' }
    }
    if ($workers.Count) {
        $worker=$workers[0]
        if ($worker.ParentProcessId -ne $State.pid -or $worker.CreationDate.ToUniversalTime() -lt $started) {
            throw 'MATLAB worker parent/start identity mismatch.'
        }
    }
    return [pscustomobject]@{running=$true;launchers=$launchers.Count;workers=$workers.Count}
}
function Start-MatlabProcess([string]$Expression,[string]$Log,$State,[string]$TargetStatePath) {
    if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'Another MATLAB/mwpython process is running.' }
    $process=Start-Process -FilePath $MatlabExe -ArgumentList @('-singleCompThread','-batch',('"'+$Expression+'"'),'-logfile',('"'+$Log+'"')) -WorkingDirectory $RepoDir -WindowStyle Hidden -PassThru
    $State.pid=$process.Id
    $State.process_start_utc=$process.StartTime.ToUniversalTime().ToString('o')
    $State.batch_expression=$Expression
    $State.log=$Log
    $State.launched=$true
    Write-JsonAtomic $TargetStatePath $State
    return $process
}
function Start-MatlabJob([string]$Mode,$State) {
    $stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')
    $log=Join-Path $RuntimeRoot "logs\${Mode}_${stamp}.log"
    $expression="cd('$($RepoDir.Replace('\','/'))'); addpath('tools/stage8_k2_raw_tangent_core_native_snr/matlab'); stage8_k2_rtc_dispatch('$Mode',pwd,'$($RuntimeRoot.Replace('\','/'))')"
    $State.last_mode=$Mode
    Start-MatlabProcess $expression $log $State $StatePath | Out-Null
}
function Invoke-Tick {
    $mutex=[Threading.Mutex]::new($false,'Local\BSInnovationStage8K2RTCTwoScenariosL8V1')
    $owned=$false
    try {
        $owned=$mutex.WaitOne(0)
        if (-not $owned) {
            if ($Action -eq 'TestProbe') { throw 'Actual Tick test could not acquire the controller mutex.' }
            return
        }
        Assert-Identity
        $state=Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        if ($state.state -in @('COMPLETE','HARD_STOPPED')) { return }
        $failure=Join-Path $RuntimeRoot 'status\hard_stop.json'
        if (Test-Path -LiteralPath $failure) { throw (Get-Content -LiteralPath $failure -Raw) }
        $active=@(Get-CimInstance Win32_Process -Filter "Name='MATLAB.exe' OR Name='mwpython.exe'")
        $inventory=Get-MatlabInventory $active $state
        if ($inventory.running) { return }
        $doneName=switch ($state.state) {
            'BEAMSPACE_RUNNING' {'beamspace_done.json'}
            'ELEMENT_RUNNING' {'element_done.json'}
            'FINALIZATION_RUNNING' {'finalize_done.json'}
            'AUDIT_RUNNING' {'audit_done.json'}
            default {''}
        }
        $done=$false
        if ($doneName) {
            $donePath=Join-Path $RuntimeRoot "status\$doneName"
            if (Test-Path -LiteralPath $donePath) {
                $marker=Get-Content -LiteralPath $donePath -Raw | ConvertFrom-Json
                $formal=Get-Content (Join-Path $RuntimeRoot 'controller\formal_identity.json') -Raw | ConvertFrom-Json
                if (-not $marker.complete -or $marker.head -ne $formal.head -or $marker.source_hash -ne $formal.source_hash) { throw 'Invalid completion marker.' }
                $done=$true
            }
        }
        $decision=Get-Decision $state.state $false $done ([bool]$state.launched)
        switch ($decision) {
            {$_ -in @('START_BEAMSPACE','RESUME_BEAMSPACE')} { $state.state='BEAMSPACE_RUNNING'; Start-MatlabJob 'BEAMSPACE' $state }
            {$_ -in @('START_ELEMENT','RESUME_ELEMENT')} { $state.state='ELEMENT_RUNNING'; Start-MatlabJob 'ELEMENT' $state }
            'START_FINALIZATION' { $state.state='FINALIZATION_RUNNING'; Start-MatlabJob 'FINALIZE' $state }
            'START_AUDIT' { $state.state='AUDIT_RUNNING'; Start-MatlabJob 'AUDIT' $state }
            {$_ -in @('READY_TO_FINALIZE','READY_FOR_AUDIT','READY_FOR_GIT_CLOSEOUT')} {
                $state.state=$decision; $state.launched=$false; $state.pid=0; Write-JsonAtomic $StatePath $state
            }
            'CLOSEOUT' {
                & (Join-Path $PSScriptRoot 'Stage8K2RTCCloseout.ps1') -RepoDir $RepoDir -RuntimeRoot $RuntimeRoot
            }
            'HARD_STOPPED' { throw 'Finalization/audit process exited without a valid completion marker.' }
        }
    } catch {
        $reason=$_.Exception.Message
        $snapshot=Join-Path $RuntimeRoot ('controller\process_stop_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'.json')
        $processes=@(Get-CimInstance Win32_Process -Filter "Name='MATLAB.exe' OR Name='mwpython.exe'" |
            Select-Object ProcessId,ParentProcessId,ExecutablePath,CommandLine,CreationDate)
        Write-JsonAtomic $snapshot $processes
        if ($reason.StartsWith('RTC_GIT_RETRY:') -and $state.state -eq 'READY_FOR_GIT_CLOSEOUT') {
            $state | Add-Member -NotePropertyName last_closeout_error -NotePropertyValue $reason -Force
            Write-JsonAtomic $StatePath $state
            return
        }
        $halt=[ordered]@{state='HARD_STOPPED';reason=$reason;process_snapshot=$snapshot;utc=[DateTime]::UtcNow.ToString('o')}
        Write-JsonAtomic $StatePath $halt
        throw
    } finally {
        if ($owned) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

switch ($Action) {
    'TestProbe' {
        $before=(Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash
        $state=Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        $active=@(Get-CimInstance Win32_Process -Filter "Name='MATLAB.exe' OR Name='mwpython.exe'")
        Write-JsonAtomic (Join-Path $RuntimeRoot 'tests\process_launch_observed.json') @($active | Select-Object ProcessId,ParentProcessId,ExecutablePath,CreationDate,CommandLine)
        $inventory=Get-MatlabInventory $active $state
        if ($inventory.workers -ne 1 -or $inventory.launchers -ne 1) { throw 'Actual launcher/worker pair was not observed.' }
        Invoke-Tick
        if ($before -ne (Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash) { throw 'Tick mutated a live-worker state.' }
        Write-JsonAtomic (Join-Path $RuntimeRoot "tests\process_launch_${PSEdition}_pass.json") @{
            pass=$true;launchers=$inventory.launchers;compute_workers=$inventory.workers;tick_state_unchanged=$true
            powershell_edition=$PSEdition
            controller_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
            observed_utc=[DateTime]::UtcNow.ToString('o')
            processes=@($active | Select-Object ProcessId,ParentProcessId,ExecutablePath,CreationDate,CommandLine)
        }
    }
    'TestLaunch' {
        Assert-Identity
        $testState=Join-Path $RuntimeRoot 'tests\process_launch_state.json'
        $reportPath=Join-Path $RuntimeRoot 'tests\process_launch_pass.json'
        if ((Test-Path -LiteralPath $testState) -or (Test-Path -LiteralPath $reportPath)) { throw 'Actual-launch test evidence exists; preserve before retesting.' }
        $state=[ordered]@{state='PROCESS_TEST_RUNNING';pid=0;process_start_utc='';batch_expression='';last_mode='TEST';log='';launched=$false}
        $pwsh=(Get-Command pwsh.exe -ErrorAction Stop).Source.Replace('\','/')
        $expression="cd('$($RepoDir.Replace('\','/'))'); addpath('tools/stage8_k2_raw_tangent_core_native_snr/tests'); stage8_k2_rtc_test_process_launch(pwd,'$($RuntimeRoot.Replace('\','/'))','$pwsh')"
        $process=Start-MatlabProcess $expression (Join-Path $RuntimeRoot 'logs\process_launch_test.log') $state $testState
        if (-not $process.WaitForExit(60000)) { throw 'Actual-launch test did not finish within 60 seconds; preserve processes for inspection.' }
        $editions=@('Desktop','Core')
        foreach ($edition in $editions) {
            $report=Get-Content -LiteralPath (Join-Path $RuntimeRoot "tests\process_launch_${edition}_pass.json") -Raw | ConvertFrom-Json
            if (-not $report.pass -or $report.powershell_edition -ne $edition -or
                $report.controller_sha256 -ne (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()) {
                throw 'Actual-launch test did not pass in both PowerShell editions.'
            }
        }
        foreach ($entry in $report.processes) {
            $remaining=Get-Process -Id $entry.ProcessId -ErrorAction SilentlyContinue
            if ($remaining -and -not $remaining.WaitForExit(10000)) { throw 'Test process remains active.' }
        }
        if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'Test process cleanup failed.' }
        if (-not $report.pass) { throw 'Actual-launch test failed.' }
        $report | Add-Member -NotePropertyName powershell_editions -NotePropertyValue $editions
        Write-JsonAtomic $reportPath $report
        'ACTUAL LAUNCH/TICK PASS: PowerShell 5.1 and 7, one compute worker, unchanged state, clean exit.'
    }
    'Test' {
        $stamp=[DateTime]::UtcNow
        $fixture=[pscustomobject]@{pid=101;process_start_utc=$stamp.ToString('o');batch_expression='test_expression';log='test.log';launched=$true}
        $command=' -singleCompThread -batch "test_expression" -logfile "test.log"'
        $launcher=[pscustomobject]@{ProcessId=101;ParentProcessId=1;ExecutablePath=$MatlabExe;CreationDate=$stamp;CommandLine=('"'+$MatlabExe+'"'+$command)}
        $worker=[pscustomobject]@{ProcessId=102;ParentProcessId=101;ExecutablePath='E:\MATLABR2022b\bin\win64\MATLAB.exe';CreationDate=$stamp.AddSeconds(1);CommandLine=('"E:\MATLABR2022b\bin\win64\MATLAB.exe"'+$command)}
        foreach ($valid in @(@(),@($launcher),@($worker),@($launcher,$worker))) {
            $inventory=Get-MatlabInventory $valid $fixture
            if ($inventory.running -ne ($valid.Count -gt 0)) { throw 'Valid process inventory rejected.' }
        }
        $decoded=$fixture | ConvertTo-Json | ConvertFrom-Json
        Get-MatlabInventory @($launcher,$worker) $decoded | Out-Null
        $typed=$fixture.PSObject.Copy(); $typed.process_start_utc=$stamp
        Get-MatlabInventory @($launcher,$worker) $typed | Out-Null
        $badParent=$worker.PSObject.Copy(); $badParent.ParentProcessId=999
        $badCommand=$worker.PSObject.Copy(); $badCommand.CommandLine='-batch unrelated'
        $unknown=$worker.PSObject.Copy(); $unknown.ExecutablePath=$null
        $foreign=$worker.PSObject.Copy(); $foreign.ExecutablePath='C:\foreign\MATLAB.exe'
        $python=$worker.PSObject.Copy(); $python.ExecutablePath='E:\MATLABR2022b\bin\win64\mwpython.exe'
        $reused=$launcher.PSObject.Copy(); $reused.CreationDate=$stamp.AddSeconds(1)
        $early=$worker.PSObject.Copy(); $early.CreationDate=$stamp.AddSeconds(-1)
        $invalid=@(@($launcher,$worker,$worker),@($launcher,$launcher),@($badParent),@($badCommand),@($unknown),@($foreign),@($python),@($reused),@($early))
        foreach ($bad in $invalid) {
            $rejected=$false
            try { Get-MatlabInventory $bad $fixture | Out-Null } catch { $rejected=$true }
            if (-not $rejected) { throw 'Invalid process inventory accepted.' }
        }
        $actual=Get-Content (Join-Path $RuntimeRoot 'tests\process_launch_pass.json') -Raw | ConvertFrom-Json
        if (-not $actual.pass -or -not $actual.tick_state_unchanged -or $actual.compute_workers -ne 1 -or
            @($actual.powershell_editions).Count -ne 2 -or
            $actual.controller_sha256 -ne (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()) {
            throw 'A passing actual-launch test for this controller revision is required.'
        }
        $cases=@(
            @('PREPARED',$false,$false,$false,'START_BEAMSPACE'),
            @('BEAMSPACE_RUNNING',$true,$false,$true,'NONE'),
            @('BEAMSPACE_RUNNING',$false,$false,$true,'RESUME_BEAMSPACE'),
            @('BEAMSPACE_RUNNING',$false,$true,$true,'START_ELEMENT'),
            @('ELEMENT_RUNNING',$false,$false,$true,'RESUME_ELEMENT'),
            @('ELEMENT_RUNNING',$false,$true,$true,'READY_TO_FINALIZE'),
            @('READY_TO_FINALIZE',$false,$false,$false,'START_FINALIZATION'),
            @('FINALIZATION_RUNNING',$false,$true,$true,'READY_FOR_AUDIT'),
            @('READY_FOR_AUDIT',$false,$false,$false,'START_AUDIT'),
            @('AUDIT_RUNNING',$false,$true,$true,'READY_FOR_GIT_CLOSEOUT'),
            @('READY_FOR_GIT_CLOSEOUT',$false,$true,$false,'CLOSEOUT'),
            @('FINALIZATION_RUNNING',$false,$false,$true,'HARD_STOPPED'),
            @('AUDIT_RUNNING',$false,$false,$true,'HARD_STOPPED'),
            @('COMPLETE',$false,$true,$true,'NONE'),
            @('HARD_STOPPED',$false,$false,$false,'NONE'))
        foreach ($case in $cases) {
            if ((Get-Decision $case[0] $case[1] $case[2] $case[3]) -ne $case[4]) { throw "State-machine test failed: $case" }
        }
        $trigger=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15) -RepetitionInterval (New-TimeSpan -Minutes 15)
        $settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -StartWhenAvailable
        if ($trigger.Repetition.Interval -ne 'PT15M' -or $settings.MultipleInstances -ne 2) { throw '15-minute/IgnoreNew contract failed.' }
        $testTask=$TaskName+'-ContractTest-'+[guid]::NewGuid().ToString('N')
        $testAction=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -NonInteractive -Command "exit 0"'
        $testPrincipal=New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
        try {
            Register-ScheduledTask -TaskName $testTask -Action $testAction -Trigger $trigger -Settings $settings -Principal $testPrincipal | Out-Null
            [xml]$registeredXml=Export-ScheduledTask -TaskName $testTask
            if ($registeredXml.Task.Triggers.TimeTrigger.Repetition.Interval -ne 'PT15M' -or
                $registeredXml.Task.Settings.MultipleInstancesPolicy -ne 'IgnoreNew') { throw 'Registered scheduler XML differs from the contract.' }
        } finally {
            if (Get-ScheduledTask -TaskName $testTask -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $testTask -Confirm:$false }
        }
        if (Get-ScheduledTask -TaskName $testTask -ErrorAction SilentlyContinue) { throw 'Test scheduled task was not removed.' }
        $source=Get-Content -LiteralPath $PSCommandPath -Raw
        if ($source -match '(?im)^\s*(while\s*\(|Start-Sleep\b)') { throw 'Polling loop forbidden.' }
        $closeout=Get-Content (Join-Path $PSScriptRoot 'Stage8K2RTCCloseout.ps1') -Raw
        if ($closeout -notmatch 'Unregister-ScheduledTask' -or $closeout -notmatch 'record two-scenario L8 results') { throw 'Closeout contract missing.' }
        Write-JsonAtomic (Join-Path $RuntimeRoot 'controller\scheduled_test_pass.json') @{pass=$true;cases=$cases.Count;valid_process_cases=6;invalid_process_cases=$invalid.Count;actual_launch=$actual;interval_minutes=15;multiple_instances='IgnoreNew'}
        'T18 PASS'
    }
    'InstallAndStart' {
        Assert-Identity
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) { throw 'Task exists; hard stop.' }
        if (Test-Path -LiteralPath $StatePath) { throw 'Controller state exists; hard stop.' }
        if ((Invoke-CheckedGit @('status','--porcelain=v1','--untracked-files=all'))) { throw 'Worktree must be clean.' }
        $head=Invoke-CheckedGit @('rev-parse','HEAD')
        if ($head -ne (Invoke-CheckedGit @('rev-parse',"origin/$Branch"))) { throw 'Branch is not pushed.' }
        $gates=Get-Content (Join-Path $RuntimeRoot 'controller\gates.json') -Raw | ConvertFrom-Json
        if (-not $gates.pass -or $gates.group_count -ne 4) { throw 'Four preflight groups required.' }
        if (-not (Test-Path (Join-Path $RuntimeRoot 'controller\formal_identity.json'))) { throw 'Formal identity missing.' }
        $formal=Get-Content (Join-Path $RuntimeRoot 'controller\formal_identity.json') -Raw | ConvertFrom-Json
        if ($formal.head -ne $head -or $formal.source_hash -ne $gates.source_hash) { throw 'Gate/formal code identity mismatch.' }
        if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'MATLAB/mwpython must be absent.' }
        $state=[ordered]@{state='PREPARED';pid=0;process_start_utc='';batch_expression='';last_mode='';log='';launched=$false}
        Write-JsonAtomic $StatePath $state
        $command="-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action Tick"
        $taskAction=New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $command -WorkingDirectory $RepoDir
        $trigger=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15) -RepetitionInterval (New-TimeSpan -Minutes 15)
        $settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -StartWhenAvailable
        $userIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $principal=New-ScheduledTaskPrincipal -UserId $userIdentity -LogonType Interactive -RunLevel Limited
        Register-ScheduledTask -TaskName $TaskName -Action $taskAction -Trigger $trigger -Settings $settings -Principal $principal -Description 'Stage8 K2 raw Tangent two-scenario L8 protocol; one transition or MATLAB launch per tick.' | Out-Null
        Invoke-Tick
    }
    'Tick' { Invoke-Tick }
    'Status' { Get-Content -LiteralPath $StatePath -Raw }
}
