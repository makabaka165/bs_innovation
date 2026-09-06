[CmdletBinding()]
param([string]$RepoDir='E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8',[switch]$RequirePruned)
$ErrorActionPreference='Stop'
$base='f1b13422a91540073ecf417c3b25f5cac552b9d6'
$branch='experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1'
if ([IO.Path]::GetFullPath($RepoDir) -ne 'E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8') { throw 'Wrong worktree.' }
if ((git -C $RepoDir branch --show-current).Trim() -ne $branch) { throw 'Wrong branch.' }
$anchors=@{
    'main'='644fc6e0041e400b6500579bba93d49f45e46990'
    'origin/main'='644fc6e0041e400b6500579bba93d49f45e46990'
    'research/stage8-k2-vincent-anchored'='a7139204d717923cb89d0d629b67f1b3ab7ae94d'
    'experiment/stage8-k2-raw-tangent-core-native-snr-v1'=$base
    'origin/experiment/stage8-k2-raw-tangent-core-native-snr-v1'=$base
}
foreach ($ref in $anchors.Keys) {
    if ((git -C $RepoDir rev-parse $ref).Trim() -ne $anchors[$ref]) { throw "Anchor changed: $ref" }
}
foreach ($tree in @('E:\bs_innovation','E:\bs_innovation_worktrees\raw-tangent')) {
    if (@(git -C $tree status --porcelain=v1 --untracked-files=all).Count) { throw "Protected worktree changed: $tree" }
}
$manifest=Import-Csv (Join-Path $RepoDir 'innovation-mining\59_stage8_k2_raw_tangent_two_scenarios_deletions.tsv') -Delimiter ([char]9)
$deletions=@{}
foreach ($item in $manifest) {
    if ($item.preserved_at_parent_commit -ne $base -or $item.path -match '(^/|\\|(^|/)\.\.(/|$))') { throw 'Deletion identity mismatch.' }
    git -C $RepoDir cat-file -e ($base+':'+$item.path)
    if ($LASTEXITCODE -ne 0) { throw "Missing preserved parent path: $($item.path)" }
    $deletions[$item.path]=$true
    if ($RequirePruned -and (Test-Path -LiteralPath (Join-Path $RepoDir $item.path))) { throw "Pruned path remains: $($item.path)" }
}
$protected=@(
    'fit_core','fit_k1_white','projected_direction','profile_scale_direct',
    'generate_observation','generate_beamspace_observation','generate_element_observation',
    'build_source','build_truth','resolution_metrics'
) | ForEach-Object { "tools/stage8_k2_raw_tangent_core_native_snr/matlab/stage8_k2_rtc_$_.m" }
$protected+=@(
    'tools/stage8_k2_classical_baselines/matlab/stage8_k2_cb_full4d_cml.m',
    'tools/stage8_k2_classical_baselines/matlab/stage8_k2_cb_music.m',
    'tools/stage8_k2_classical_baselines/matlab/stage8_k2_cb_peak_picker.m',
    'tools/stage8_k2_classical_baselines/matlab/stage8_k2_cb_build_element_manifold.m',
    'tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_vertical_covariance.m',
    'tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_reshape_element_snapshots.m',
    'tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_fbss_covariance.m',
    'tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_root_music.m',
    'tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_conditional_az_cml.m'
)
foreach ($filename in $protected) {
    # Compare repository bytes; core.autocrlf may change checkout line endings.
    $source=(git -C $RepoDir rev-parse ($base+':'+$filename)).Trim()
    $current=(git -C $RepoDir hash-object $filename).Trim()
    if ($source -ne $current) {
        throw "Scientific core bytes changed: $filename"
    }
}
function Test-AllowedPath([string]$Path) {
    return $Path -match '^(tools/stage8_k2_raw_tangent_core_native_snr/|tools/stage8_k2_(classical|subspace)_baselines/(README.md|matlab/stage8_k2_(cb|sb)_constants.m)$|summary/(summary.md|tangent_algorithm_full_detailed.md)$|innovation-mining/(59_stage8_k2_raw_tangent_two_scenarios_|60_stage8_k2_raw_tangent_two_scenarios_|figures/60_|00_DOCUMENT_STATUS_INDEX.md$|stage8_execution_prompts/(README.md|active/README.md|archive/60_stage8_k2_raw_tangent_two_scenarios_l8_execution.md)$))'
}
foreach ($line in @(git -C $RepoDir diff --no-renames --name-status $base)) {
    $parts=$line -split ([char]9)
    if ($parts[0] -eq 'D' -and $deletions.ContainsKey($parts[1])) { continue }
    if ($parts[0] -in @('A','M') -and (Test-AllowedPath $parts[1]) -and $parts[1] -notin $protected) { continue }
    throw "Out-of-scope change: $line"
}
foreach ($filename in @(git -C $RepoDir ls-files --others --exclude-standard)) {
    if (-not (Test-AllowedPath $filename)) { throw "Out-of-scope untracked path: $filename" }
}
'SCOPE PASS; 19 scientific core files byte-identical to parent.'
