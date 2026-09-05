[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('Archive','Resume')][string]$Action,
    [ValidateSet('LauncherCount','Timestamp')][string]$Incident='LauncherCount')
$ErrorActionPreference='Stop'
$repo='E:\bs_innovation_worktrees\raw-tangent'
$runtime='E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-core-native-snr-v1'
$archive=Join-Path $runtime 'backup\launch_incident_d4e2517'
$branch='experiment/stage8-k2-raw-tangent-core-native-snr-v1'
$oldHead='d4e2517bf860efeabbf40925af44ba17bff85495'
$expectedReason='Multiple MATLAB/mwpython processes detected.'
$expectedCount=45
$auditName='incident_readonly_audit.json'
$incidentName='launch_incident.json'
if ($Incident -eq 'Timestamp') {
    $archive=Join-Path $runtime 'backup\timestamp_incident_7c4b95a'
    $oldHead='7c4b95a750875c53d554056bc42b01c54b49408e'
    $expectedReason='MATLAB launcher identity mismatch.'
    $expectedCount=61
    $auditName='timestamp_readonly_audit.json'
    $incidentName='timestamp_incident.json'
}
$controller=Join-Path $runtime 'controller'
$statePath=Join-Path $controller 'controller_state.json'
function Write-Atomic([string]$Filename,$Value) {
    if (Test-Path -LiteralPath "$Filename.tmp") { throw 'Existing recovery temporary file.' }
    [IO.File]::WriteAllText("$Filename.tmp",($Value | ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath "$Filename.tmp" -Destination $Filename -Force
}
function Assert-Hash([string]$Filename,[string]$Expected) {
    if ((Get-FileHash -LiteralPath $Filename -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Expected.ToLowerInvariant()) {
        throw "Recovery artifact hash mismatch: $Filename"
    }
}
$mutex=[Threading.Mutex]::new($false,'Local\BSInnovationStage8K2RTCNativeSNRV1')
$owned=$false
try {
    $owned=$mutex.WaitOne(0)
    if (-not $owned) { throw 'Controller is active; recovery cannot proceed.' }
    & (Join-Path $PSScriptRoot 'Stage8K2RTCScope.ps1') -RepoDir $repo -RequirePruned
    if ($LASTEXITCODE -ne 0) { throw 'Scope check failed.' }
    if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'MATLAB/mwpython must be absent.' }
    $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.state -ne 'HARD_STOPPED' -or $state.reason -ne $expectedReason) {
        throw 'Recovery is restricted to the recorded launcher-count incident.'
    }
    $oldFormal=Get-Content (Join-Path $controller 'formal_identity.json') -Raw | ConvertFrom-Json
    if ($oldFormal.head -ne $oldHead) { throw 'Unexpected prior formal identity.' }
    if (@(Get-ChildItem -LiteralPath $runtime -Recurse -File | Where-Object { $_.Extension -in @('.tmp','.lock') }).Count) {
        throw 'Temporary files/locks require inspection.'
    }
    if ($Action -eq 'Archive') {
        if (Test-Path -LiteralPath $archive) { throw 'Incident archive already exists; do not overwrite.' }
        $audit=Get-Content (Join-Path $controller $auditName) -Raw | ConvertFrom-Json
        if (-not $audit.pass -or $audit.checkpoint_count -ne $expectedCount -or -not $audit.checkpoint_bytes_unchanged -or
            $audit.old_identity.source_hash -ne $oldFormal.source_hash) { throw 'Read-only checkpoint audit missing.' }
        $beam=Join-Path $runtime 'checkpoints\beamspace'
        if (@(Get-ChildItem -LiteralPath $beam -File).Count -ne $expectedCount -or
            @(Get-ChildItem -LiteralPath (Join-Path $runtime 'checkpoints\element') -File).Count) { throw 'Unexpected checkpoint inventory.' }
        foreach ($entry in $audit.checkpoints) { Assert-Hash (Join-Path $beam $entry.name) $entry.sha256 }
        $destination=Join-Path $archive 'checkpoints\beamspace'
        if (-not [IO.Path]::GetFullPath($destination).StartsWith($runtime+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Archive escaped runtime.' }
        New-Item -ItemType Directory -Path $destination -ErrorAction Stop | Out-Null
        $metadata=Join-Path $archive 'controller'
        New-Item -ItemType Directory -Path $metadata -ErrorAction Stop | Out-Null
        foreach ($name in @('controller_state.json','formal_identity.json','gates.json',$incidentName,$auditName)) {
            Copy-Item -LiteralPath (Join-Path $controller $name) -Destination (Join-Path $metadata $name)
            Assert-Hash (Join-Path $metadata $name) (Get-FileHash -LiteralPath (Join-Path $controller $name) -Algorithm SHA256).Hash
        }
        foreach ($entry in $audit.checkpoints) {
            Move-Item -LiteralPath (Join-Path $beam $entry.name) -Destination (Join-Path $destination $entry.name)
            Assert-Hash (Join-Path $destination $entry.name) $entry.sha256
        }
        Write-Atomic (Join-Path $archive 'archive_manifest.json') @{
            pass=$true;policy='ARCHIVE_BYTE_IDENTICAL_THEN_RECOMPUTE_WITH_STRICT_NEW_IDENTITY'
            old_head=$oldHead;old_source_hash=$oldFormal.source_hash;checkpoint_count=$expectedCount
            checkpoints=$audit.checkpoints;archived_utc=[DateTime]::UtcNow.ToString('o')
            user_authorization='User requested fixing the root cause and continuing the protocol after HARD_STOPPED.'
        }
        "ARCHIVE PASS: $expectedCount byte-identical checkpoints preserved; controller remains HARD_STOPPED."
    } else {
        $manifest=Get-Content (Join-Path $archive 'archive_manifest.json') -Raw | ConvertFrom-Json
        if (-not $manifest.pass -or $manifest.checkpoint_count -ne $expectedCount) { throw 'Archive incomplete.' }
        foreach ($entry in $manifest.checkpoints) { Assert-Hash (Join-Path $archive ('checkpoints\beamspace\'+$entry.name)) $entry.sha256 }
        Assert-Hash $statePath (Get-FileHash -LiteralPath (Join-Path $archive 'controller\controller_state.json') -Algorithm SHA256).Hash
        Assert-Hash (Join-Path $controller 'formal_identity.json') (Get-FileHash -LiteralPath (Join-Path $archive 'controller\formal_identity.json') -Algorithm SHA256).Hash
        if (@(Get-ChildItem -LiteralPath (Join-Path $runtime 'checkpoints') -Recurse -File).Count) { throw 'New checkpoint directories must be empty.' }
        if (@(Get-ChildItem -LiteralPath (Join-Path $runtime 'status') -File | Where-Object { $_.Name -ne 'latest.json' }).Count) { throw 'Unexpected completion/failure marker.' }
        $head=(& git -C $repo rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0 -or $head -eq $oldHead) { throw 'Recovery commit missing.' }
        if ($head -ne (& git -C $repo rev-parse "origin/$branch").Trim() -or
            @(& git -C $repo status --porcelain=v1 --untracked-files=all).Count) { throw 'Recovery must be committed, pushed and clean.' }
        $gates=Get-Content (Join-Path $controller 'gates.json') -Raw | ConvertFrom-Json
        $formal=Get-Content (Join-Path $controller 'recovered_identity.json') -Raw | ConvertFrom-Json
        if (-not $gates.pass -or $gates.test_count -ne 18 -or $formal.head -ne $head -or
            $formal.source_hash -ne $gates.source_hash) { throw 'Recovery identity/gates mismatch.' }
        [xml]$task=Export-ScheduledTask -TaskName 'BSInnovation-Stage8K2-RawTangentCore-NativeSNR-V1'
        if ($task.Task.Triggers.TimeTrigger.Repetition.Interval -ne 'PT15M' -or
            $task.Task.Settings.MultipleInstancesPolicy -ne 'IgnoreNew') { throw 'Existing task contract changed.' }
        Write-Atomic (Join-Path $controller 'formal_identity.json') $formal
        Write-Atomic (Join-Path $controller 'recovery_complete.json') @{
            recovered_utc=[DateTime]::UtcNow.ToString('o');old_head=$oldHead;new_head=$head
            source_hash=$formal.source_hash;archived_checkpoints=$expectedCount;recompute_count=$expectedCount
            checkpoint_identity_validation='UNCHANGED_EXACT_HEAD_AND_SOURCE_HASH';archive=$archive
        }
        Write-Atomic $statePath ([ordered]@{state='PREPARED';pid=0;process_start_utc='';batch_expression='';last_mode='';log='';launched=$false})
        'RECOVERY PASS: new identity frozen; archived trials will be recomputed.'
    }
} finally {
    if ($owned) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
if ($Action -eq 'Resume') { & (Join-Path $PSScriptRoot 'Stage8K2RTCController.ps1') -Action Tick }
