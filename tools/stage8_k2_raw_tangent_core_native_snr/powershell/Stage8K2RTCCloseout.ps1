[CmdletBinding()]
param([string]$RepoDir='E:\bs_innovation_worktrees\raw-tangent',
    [string]$RuntimeRoot='E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-core-native-snr-v1')
$ErrorActionPreference='Stop'
$branch='experiment/stage8-k2-raw-tangent-core-native-snr-v1'
$task='BSInnovation-Stage8K2-RawTangentCore-NativeSNR-V1'
if ($RepoDir -ne 'E:\bs_innovation_worktrees\raw-tangent') { throw 'Wrong worktree.' }
if (@(Get-Process MATLAB,mwpython -ErrorAction SilentlyContinue).Count) { throw 'MATLAB/mwpython still active.' }
$audit=Get-Content (Join-Path $RuntimeRoot 'status\audit_done.json') -Raw | ConvertFrom-Json
if (-not $audit.complete -or -not $audit.pass) { throw 'Independent audit missing.' }
if ((git -C $RepoDir rev-parse HEAD).Trim() -ne $audit.head) { throw 'HEAD changed after the audit.' }
$modified=@(git -C $RepoDir diff --name-only HEAD)
$untracked=@(git -C $RepoDir ls-files --others --exclude-standard)
foreach ($filename in @($modified)+@($untracked)) {
    if ($filename -notmatch '^innovation-mining/(58_|figures/58_)') { throw "Unexpected closeout change: $filename" }
}
$manifestPath=Join-Path $RepoDir 'innovation-mining\58_stage8_k2_raw_tangent_runtime_manifest.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
foreach ($artifact in $manifest.artifacts) {
    if ((Get-FileHash -LiteralPath (Join-Path $RepoDir $artifact.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artifact.sha256) { throw "Artifact changed: $($artifact.path)" }
}
& (Join-Path $PSScriptRoot 'Stage8K2RTCScope.ps1') -RepoDir $RepoDir -RequirePruned
if ($LASTEXITCODE -ne 0) { throw 'Scope audit failed.' }
$manifest | Add-Member -NotePropertyName 'status' -NotePropertyValue 'STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_COMPLETE' -Force
$manifest | Add-Member -NotePropertyName 'independent_audit_status' -NotePropertyValue 'PASS' -Force
$manifest | Add-Member -NotePropertyName 'nominal_target_max_error_db' -NotePropertyValue $audit.nominal_max_error_db -Force
$manifest | Add-Member -NotePropertyName 'active_tangent_cache_count' -NotePropertyValue 0 -Force
$manifest | Add-Member -NotePropertyName 'active_fixed_k2_call_count' -NotePropertyValue 0 -Force
$manifest | Add-Member -NotePropertyName 'active_correlated_noise_count' -NotePropertyValue 0 -Force
$manifest | Add-Member -NotePropertyName 'shared_compatibility_status' -NotePropertyValue 'DORMANT_SHARED_COMPATIBILITY_NOT_REACHED' -Force
[IO.File]::WriteAllText($manifestPath,($manifest | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
git -C $RepoDir add -- 'innovation-mining/58_*' 'innovation-mining/figures/58_*'
if ($LASTEXITCODE -ne 0) { throw 'Result staging failed.' }
git -C $RepoDir commit -m 'docs(stage8-k2): record raw Tangent native-SNR results'
if ($LASTEXITCODE -ne 0) { throw 'Result commit failed.' }
git -C $RepoDir push origin $branch
if ($LASTEXITCODE -ne 0) { throw 'Result push failed.' }
$head=(git -C $RepoDir rev-parse HEAD).Trim()
$remote=(git -C $RepoDir rev-parse "origin/$branch").Trim()
if ($head -ne $remote -or @(git -C $RepoDir status --porcelain=v1 --untracked-files=all).Count) { throw 'Final Git identity failed.' }
if (@(Get-ChildItem -LiteralPath $RuntimeRoot -Recurse -File | Where-Object { $_.Extension -in @('.tmp','.lock') }).Count) { throw 'Temporary files or locks remain.' }
Unregister-ScheduledTask -TaskName $task -Confirm:$false
if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) { throw 'Scheduled task was not removed.' }
$final=[ordered]@{state='COMPLETE';status='STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_COMPLETE';result_commit=$head;push=$true;clean=$true;scheduled_task='ABSENT';next='USER_REVIEW'}
$json=$final | ConvertTo-Json
$filename=Join-Path $RuntimeRoot 'controller\controller_state.json'
$temporary="$filename.tmp"
if (Test-Path -LiteralPath $temporary) { throw 'Existing closeout temporary state.' }
[IO.File]::WriteAllText($temporary,$json,[Text.UTF8Encoding]::new($false))
Move-Item -LiteralPath $temporary -Destination $filename -Force
