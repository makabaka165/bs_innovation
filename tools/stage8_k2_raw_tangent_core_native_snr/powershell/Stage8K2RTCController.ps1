[CmdletBinding()]
param(
    [ValidateSet('InstallAndStart','Tick','Status','Test')][string]$Action='Status',
    [string]$RepoDir='E:\bs_innovation_worktrees\raw-tangent',
    [string]$RuntimeRoot='E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-core-native-snr-v1'
)
$ErrorActionPreference='Stop'
$TaskName='BSInnovation-Stage8K2-RawTangentCore-NativeSNR-V1'
$MatlabExe='E:\MATLABR2022b\bin\matlab.exe'
$StatePath=Join-Path $RuntimeRoot 'controller\controller_state.json'
$Branch='experiment/stage8-k2-raw-tangent-core-native-snr-v1'

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
    if ([IO.Path]::GetFullPath($RepoDir) -ne 'E:\bs_innovation_worktrees\raw-tangent' -or
        [IO.Path]::GetFullPath($RuntimeRoot) -ne 'E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-core-native-snr-v1') { throw 'Wrong experiment paths.' }
    if ((Invoke-CheckedGit @('branch','--show-current')) -ne $Branch) { throw 'Wrong branch.' }
    foreach ($ref in @('main','origin/main')) {
        if ((Invoke-CheckedGit @('rev-parse',$ref)) -ne '644fc6e0041e400b6500579bba93d49f45e46990') { throw 'Main anchor moved.' }
    }
    if ((Invoke-CheckedGit @('rev-parse','research/stage8-k2-vincent-anchored')) -ne 'a7139204d717923cb89d0d629b67f1b3ab7ae94d') { throw 'Research anchor moved.' }
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
function Start-MatlabJob([string]$Mode,$State) {
    if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'Another MATLAB/mwpython process is running.' }
    $stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')
    $log=Join-Path $RuntimeRoot "logs\${Mode}_${stamp}.log"
    $expression="cd('$($RepoDir.Replace('\','/'))'); addpath('tools/stage8_k2_raw_tangent_core_native_snr/matlab'); stage8_k2_rtc_dispatch('$Mode',pwd,'$($RuntimeRoot.Replace('\','/'))')"
    $process=Start-Process -FilePath $MatlabExe -ArgumentList @('-singleCompThread','-batch',('"'+$expression+'"'),'-logfile',('"'+$log+'"')) -WorkingDirectory $RepoDir -WindowStyle Hidden -PassThru
    $State.pid=$process.Id
    $State.process_start_utc=$process.StartTime.ToUniversalTime().ToString('o')
    $State.last_mode=$Mode
    $State.log=$log
    $State.launched=$true
    Write-JsonAtomic $StatePath $State
}
function Invoke-Tick {
    $mutex=[Threading.Mutex]::new($false,'Local\BSInnovationStage8K2RTCNativeSNRV1')
    $owned=$false
    try {
        $owned=$mutex.WaitOne(0)
        if (-not $owned) { return }
        Assert-Identity
        $state=Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        if ($state.state -in @('COMPLETE','HARD_STOPPED')) { return }
        $failure=Join-Path $RuntimeRoot 'status\hard_stop.json'
        if (Test-Path -LiteralPath $failure) { throw (Get-Content -LiteralPath $failure -Raw) }
        $active=@(Get-CimInstance Win32_Process -Filter "Name='MATLAB.exe' OR Name='mwpython.exe'")
        if ($active.Count -gt 1) { throw 'Multiple MATLAB/mwpython processes detected.' }
        $running=$active.Count -eq 1
        if ($running) {
            if ($active[0].CommandLine -notmatch 'stage8_k2_rtc_dispatch') { throw 'Unrelated MATLAB process detected.' }
            return
        }
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
        $halt=[ordered]@{state='HARD_STOPPED';reason=$_.Exception.Message;utc=[DateTime]::UtcNow.ToString('o')}
        Write-JsonAtomic $StatePath $halt
        throw
    } finally {
        if ($owned) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

switch ($Action) {
    'Test' {
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
        if ($closeout -notmatch 'Unregister-ScheduledTask' -or $closeout -notmatch 'record raw Tangent native-SNR results') { throw 'Closeout contract missing.' }
        Write-JsonAtomic (Join-Path $RuntimeRoot 'controller\scheduled_test_pass.json') @{pass=$true;cases=$cases.Count;interval_minutes=15;multiple_instances='IgnoreNew'}
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
        if (-not $gates.pass -or $gates.test_count -ne 18) { throw '18/18 gates required.' }
        if (-not (Test-Path (Join-Path $RuntimeRoot 'controller\formal_identity.json'))) { throw 'Formal identity missing.' }
        $formal=Get-Content (Join-Path $RuntimeRoot 'controller\formal_identity.json') -Raw | ConvertFrom-Json
        if ($formal.head -ne $head -or $formal.source_hash -ne $gates.source_hash) { throw 'Gate/formal code identity mismatch.' }
        if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'MATLAB/mwpython must be absent.' }
        $state=[ordered]@{state='PREPARED';pid=0;process_start_utc='';last_mode='';log='';launched=$false}
        Write-JsonAtomic $StatePath $state
        $command="-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action Tick"
        $taskAction=New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $command -WorkingDirectory $RepoDir
        $trigger=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15) -RepetitionInterval (New-TimeSpan -Minutes 15)
        $settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -StartWhenAvailable
        $userIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $principal=New-ScheduledTaskPrincipal -UserId $userIdentity -LogonType Interactive -RunLevel Limited
        Register-ScheduledTask -TaskName $TaskName -Action $taskAction -Trigger $trigger -Settings $settings -Principal $principal -Description 'Stage8 K2 raw Tangent native-SNR protocol; one transition or MATLAB launch per tick.' | Out-Null
        Invoke-Tick
    }
    'Tick' { Invoke-Tick }
    'Status' { Get-Content -LiteralPath $StatePath -Raw }
}
