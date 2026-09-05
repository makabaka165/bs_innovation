# Raw Tangent Core Native-SNR Experiment

Protocol: `STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_V1`.

Branch: `experiment/stage8-k2-raw-tangent-core-native-snr-v1`.

Status: FIXED_TESTS_18_OF_18_PASS. Formal launch requires the matching source hash, a pushed tool commit, and manifest-controlled pruning. See the committed 58 fixed-tests JSON for the complete gate record.

The active scientific target is `TANGENT_PROFILE_CORE`: white Beamspace K1 DML center, projected derivative direction and full two-target manifold scale search. Both native domains use IID circular complex Gaussian noise with nominal variance equal to clean signal energy divided by linear SNR and sample count. Realized noise power is unconstrained.

The registration is 1680 scenarios (7 SNR values, 3 snapshot counts, 4 profiles, 20 replicates), 240 common base realizations and 13440 method rows. Three Beamspace methods share Z; five Element methods share Y. Cross-domain comparisons are scenario-matched native-SNR references.

See [the protocol](../../innovation-mining/57_stage8_k2_raw_tangent_core_native_snr_theory_and_protocol.md) and [the pre-deletion manifest](../../innovation-mining/57_stage8_k2_raw_tangent_pruning_manifest.csv). Existing 43-48 evidence is historical Safe reference only. Production integration is not authorized.

## Numerical Contract

The frozen physical WHITE model has 15 beams and whitening rank 15; its measured whitening residual is recorded without changing the existing builder. Noise is generated directly after whitening, so its covariance is IID by construction.

Core internally divides Z by its Frobenius norm for scale-consistent floating-point comparisons, then restores RSS, concentrated likelihood and trace scores to the original observation scale. This changes no exact DML maximizer and does not use truth or SNR. T4 requires center differences <= 1e-4 degrees, axis-vector differences <= 1e-6, and rho/endpoint differences <= 1e-3 degrees, consistent with the frozen inner and outer optimizer tolerances. The observation scaling identity must hold to relative error <= 1e-12. Development failure logs remain in the new runtime; no formal result is used to tune these tolerances.

The classical MUSIC kernel retains two legacy cardinality fields solely for runtime amortization. The adapter supplies literal zero placeholders, containing no SNR value or profile identity, and records dictionary preparation time over the correct 1120 applicable trials. The original scientific kernel stays byte-identical. Structural equal-elevation applicability is decided by the runner before fitting and passed as booleans; no profile label enters an estimator.

## Execution

MATLAB R2022b, one process, `-singleCompThread`. Run tests from this worktree:

```matlab
addpath('tools/stage8_k2_raw_tangent_core_native_snr/matlab');
addpath('tools/stage8_k2_raw_tangent_core_native_snr/tests');
stage8_k2_rtc_run_tests(pwd, ...
    'E:/bs_innovation_runtime/experiment_stage8-k2-raw-tangent-core-native-snr-v1');
```

After tool/pruning commits are pushed, freeze `controller/formal_identity.json` using `stage8_k2_rtc_code_identity`. Its source hash must equal the gate report. Then install the controller:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/stage8_k2_raw_tangent_core_native_snr/powershell/Stage8K2RTCController.ps1 -Action InstallAndStart
```

Each 15-minute tick takes a mutex, reads state, and launches at most one MATLAB process or performs one transition. Beamspace precedes Element, followed by finalization, a fresh read-only scientific audit, result commit/push, and task removal. Errors preserve the runtime and enter HARD_STOPPED. An interrupted trial process resumes only through validated checkpoints; an existing partial `.tmp` is a hard error. The controller uses the current Windows user's interactive logon, so scheduled ticks require that user to remain logged in.

## Plot-Only Regeneration

Only the plotting directory is needed. No runtime or estimator path is required:

```matlab
addpath('tools/stage8_k2_raw_tangent_core_native_snr/plotting');
stage8_k2_rtc_plot_from_committed_data('innovation-mining','regenerated_figures');
```

The two inputs are the committed `58_stage8_k2_raw_tangent_plot_data.csv` and `58_stage8_k2_raw_tangent_rho_trace_representatives.mat`. CSV angles are JSON matrices. Rates use applicable trials as their denominator; error quantiles use valid fits. Structural N/A is reported separately. Representative traces cover replicate 1 at each registered SNR/Profile/L. Fixture files under `tests/fixtures` are labeled test data and are never merged into formal evidence.
