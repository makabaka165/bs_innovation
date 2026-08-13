# Stage8 K2 Unified White-SNR All-Classical Baselines

Protocol:
`STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_V2`

This isolated tool runs only four registered element-domain references on the
immutable 1680 evidence-44 trials:

- `ELEMENT_MUSIC_K2`;
- `ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML`;
- `ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML`; and
- `ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML`.

The six methods already present in evidence 44 and 46 are read-only inputs.
They are never refit. Scientific implementations are called from the frozen
classical and structured-subspace tools.

Run the twelve MATLAB contract tests with one computation thread:

```matlab
repo_dir = 'E:\bs_innovation';
runtime_root = ...
    'E:\bs_innovation_runtime\stage8_k2_white_snr_all_classical_baselines_v2';
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_all_classical_baselines', 'matlab'));
out = stage8_k2_wacb_run_tests(repo_dir, runtime_root);
disp(out.status);
```

Run the thirteenth controller test from PowerShell, then install the formal
15-minute scheduled controller with `Stage8K2WACBController.ps1 -Action
InstallAndStart`. The controller owns resume, fresh-session finalization,
independent audit, Git closeout, push, and task removal. Interactive Codex
polling is not part of the execution contract.

Formal MATLAB sessions require R2022b, `-singleCompThread`, no parallel pool,
a clean pushed work branch, and the fixed runtime root documented above.
