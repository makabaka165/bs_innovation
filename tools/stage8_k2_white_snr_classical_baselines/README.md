# Stage8 K2 White-SNR Classical Baselines

Protocol:
`STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_FINAL_COMPARISON_V1`

This isolated MATLAB R2022b runner reconstructs the immutable evidence-44
white-SNR trials and adds three fixed-schema rows per trial:

- finite-budget `FULL4D_BEAMSPACE_CML_MULTISTART` on all 1680 trials;
- standard `BEAMSPACE_MUSIC_K2` on all trials, with 560 explicit `L=1`
  not-applicable rows; and
- `FULL4D_ELEMENT_CML_MULTISTART` on the preregistered 160-trial subset,
  with explicit placeholders elsewhere.

The tool calls the frozen trial generator and classical baseline
implementations. It does not refit or modify Core or Tangent, and it does not
change any frozen evidence or production code.

Run the registered tests with one MATLAB computation thread:

```matlab
repo_dir = 'E:\bs_innovation';
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_classical_baselines', 'matlab'));
out = stage8_k2_wcb_run_tests(repo_dir);
disp(out.status);
```

Formal run or resume:

```matlab
out = stage8_k2_wcb_run( ...
    'E:\bs_innovation', ...
    'E:\bs_innovation_runtime\stage8_k2_white_snr_classical_baselines_v1');
disp(out.status);
```

After the first session returns `READY_TO_FINALIZE`, run the same command in a
fresh MATLAB session. Then run `stage8_k2_wcb_verify` in a third fresh session
for the independent read-only audit.

Formal execution requires a clean, pushed work branch, MATLAB R2022b,
`-singleCompThread`, one MATLAB process, and no parallel pool.
