# Raw Tangent: Two Scenarios, L=8

Protocol: STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_V1.
Branch: experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1.
Parent: f1b13422a91540073ecf417c3b25f5cac552b9d6.
Worktree: E:/bs_innovation_worktrees/raw-tangent-two-scenarios-l8.
Runtime: E:/bs_innovation_runtime/experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1.

[Protocol](../../innovation-mining/59_stage8_k2_raw_tangent_two_scenarios_l8_protocol.md) /
[deletion plan](../../innovation-mining/59_stage8_k2_raw_tangent_two_scenarios_deletions.tsv) /
[preflight record](../../innovation-mining/59_stage8_k2_raw_tangent_two_scenarios_preflight.json).
The current [results](../../innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_results.md) and [runtime manifest](../../innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_runtime_manifest.json) are generated after all checkpoints exist. Completion requires independent audit PASS; performance is never an integrity gate.

## Registration

SC_A: center [8,10] deg, separation 0.45 deg, axis 30 deg, secondary power 0 dB, correlation magnitude 0.
SC_B: identical geometry, secondary power -3 dB, correlation magnitude 0.7.
Both use the parent's source construction and source-seeded correlation phase.
L=8 only; SNR [-6,0,6,10,14,18,22] dB; 20 replicates per exact cell.
280 scenarios / 40 common bases / 560 native observations and checkpoints / 1400 method rows / 14 representative Tangent traces.

Same Beamspace Z: TANGENT_PROFILE_CORE, FULL4D_BEAMSPACE_CML_MULTISTART, BEAMSPACE_MUSIC_K2.
Same Element Y_e: FULL4D_ELEMENT_CML_MULTISTART, ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML.
All five methods are structurally applicable in both scenarios. Invalid peaks, roots or rho remain algorithmic failures.

These representative scenarios were designed after the parent results were viewed. They are not a blind holdout. SC_B changes both source power and correlation; neither causal effect is isolated.

## Frozen Science

Physical WHITE context: PRIMARY_RECT_E14_A31, 2080 elements, 15 whitened beams, the original local domain and 21 coarse points.
Native IID complex Gaussian noise variance is clean energy / (linear SNR * sample count). Signal is fixed while noise scales; the observed noise norm is not forced.
Core center normalization, projected Jacobian direction, full-manifold rho profile and all optimizer budgets remain unchanged.
Full4D, Beamspace MUSIC, Root/FBSS/conditional azimuth and physical/DML kernels preserve parent Git blob bytes. Windows checkout CRLF conversion is not a scientific edit.
Default baseline constants retain scientific budgets but lose obsolete experiment registration. The Element wrapper mechanically extracts Root plus conditional azimuth; unused Element MUSIC resources are removed.
MUSIC preparation time is amortized over the actual 280 applicable trials.

Localization: d_max_bw <= 0.1. Strict resolution: d_max_bw <= min(0.1,0.4*rho_true_bw).
RMSE and d_max retain separate label assignments. Error quantiles use valid fits with valid counts alongside them.
Every exact cell has 20 trials; one outcome represents 5 percentage points. Pooled SNR tables are supplementary to scenario tables.
No active Tangent cache, fixed-K2 fallback, Toeplitz path or cross-domain paired wins/losses.

## Execution

MATLAB R2022b, -singleCompThread, one verified compute worker. Its launcher and engine child count as one worker.
Four preflight groups reuse 18 inherited checks: configuration/dependencies, SNR/metrics, four smoke scenarios and output wiring, and controller wiring.
Smoke uses SC_A/SC_B x {-6,22} dB x replicate 1, writes only runtime/tests/smoke, and never becomes formal checkpoints.
Static analysis uses MATLAB checkcode; all resolved source paths must be in this worktree. Parent numerical tolerances are retained.

With MATLAB absent, run the bounded Stage8K2RTCController.ps1 -Action TestLaunch once. Then run stage8_k2_rtc_run_tests from this worktree.
Commit/push implementation B after all four groups pass, freeze formal_identity.json using stage8_k2_rtc_code_identity, and run Stage8K2RTCController.ps1 -Action InstallAndStart.
Only the new branch is pushed.

The Windows task BSInnovation-Stage8K2-RawTangent-TwoScenarios-L8-V1 runs every 15 minutes using the current user's interactive logon, IgnoreNew and an experiment mutex.
Each Tick reads state once and exits. It advances Beamspace -> Element -> Finalize -> fresh read-only audit -> Git closeout.
Logout or offline periods do not guarantee execution; a later eligible Tick resumes valid checkpoints.
Errors preserve process snapshots and runtime evidence. Unknown temporary checkpoints stop writes. Git failures retry closeout without rerunning estimators or creating duplicate result commits.
Successful closeout archives execution authority, marks NO_ACTIVE_STAGE8_EXECUTION / NEXT=USER_REVIEW, removes the task and preserves worktree/runtime. Merge is not authorized.

## Plot-Only Regeneration

Add only tools/stage8_k2_raw_tangent_core_native_snr/plotting to MATLAB's path, then call:
stage8_k2_rtc_plot_from_committed_data('innovation-mining','regenerated_figures')

The only inputs are 60_stage8_k2_raw_tangent_two_scenarios_plot_data.csv and 60_stage8_k2_raw_tangent_two_scenarios_rho_trace_representatives.mat.
Eight scenario-specific figures contain rates, valid sample counts, errors, Element-native references and Tangent diagnostics. No runtime or estimator call is needed.

## Historical Evidence

[Parent experiment](https://github.com/makabaka165/bs_innovation/tree/f1b13422a91540073ecf417c3b25f5cac552b9d6) preserves deleted 57/58 evidence, fixtures and retired entry points.
Earlier 43-48 evidence is historical only and remains unchanged. It is never read into this experiment.
