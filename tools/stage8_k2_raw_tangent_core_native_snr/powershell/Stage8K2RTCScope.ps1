[CmdletBinding()]
param([string]$RepoDir='E:\bs_innovation_worktrees\raw-tangent',[switch]$RequirePruned)
$ErrorActionPreference='Stop'
$base='644fc6e0041e400b6500579bba93d49f45e46990'
if ((git -C $RepoDir branch --show-current).Trim() -ne 'experiment/stage8-k2-raw-tangent-core-native-snr-v1') { throw 'Wrong branch.' }
foreach ($ref in @('main','origin/main')) {
    if ((git -C $RepoDir rev-parse $ref).Trim() -ne $base) { throw 'Main ref changed.' }
}
if ((git -C $RepoDir rev-parse research/stage8-k2-vincent-anchored).Trim() -ne 'a7139204d717923cb89d0d629b67f1b3ab7ae94d') { throw 'Research ref changed.' }
if (@(git -C 'E:\bs_innovation' status --porcelain=v1 --untracked-files=all).Count) { throw 'Main worktree changed.' }
$manifest=Import-Csv (Join-Path $RepoDir 'innovation-mining\57_stage8_k2_raw_tangent_pruning_manifest.csv')
$deletions=@{}
foreach ($item in $manifest) {
    if ($item.retained_in_main_flag -ne 'true') { throw 'Manifest retention flag mismatch.' }
    if ($item.action -eq 'ABSENT_AT_BASE') { continue }
    $blob=(git -C $RepoDir rev-parse "${base}:$($item.path)").Trim()
    if ($blob -ne $item.blob_sha) { throw "Manifest blob mismatch: $($item.path)" }
    $deletions[$item.path]=$true
    if ($RequirePruned -and (Test-Path -LiteralPath (Join-Path $RepoDir $item.path))) { throw "Pruned path remains: $($item.path)" }
}
$changes=@(git -C $RepoDir diff --name-status $base)
foreach ($line in $changes) {
    $parts=$line -split "`t"
    if ($parts[0] -eq 'D' -and $deletions.ContainsKey($parts[1])) { continue }
    if ($parts[0] -eq 'A' -and $parts[1] -match '^(tools/stage8_k2_raw_tangent_core_native_snr/|innovation-mining/(57_|58_|figures/58_))') { continue }
    if ($parts[0] -eq 'M' -and $parts[1] -match '^(summary/|innovation-mining/00_DOCUMENT_STATUS_INDEX.md$|innovation-mining/stage8_execution_prompts/.*(README.md|MANIFEST.csv)$)') { continue }
    throw "Out-of-scope change: $line"
}
'SCOPE PASS'
