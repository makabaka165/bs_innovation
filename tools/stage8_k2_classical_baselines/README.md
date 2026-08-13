# Stage8 K2 Classical Baselines

Protocol: `STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_V1`

This isolated MATLAB R2022b tool reconstructs the exact 72 TP1 element
observations, verifies every frozen evidence-31 element hash, and compares the
frozen Core/Tangent rows with deterministic finite-multistart full4D CML and
standard known-K=2 MUSIC in beamspace and the exactly whitened element domain.
It does not modify or refit the frozen methods.

Run the five contract tests with one MATLAB computation thread:

```matlab
repo_dir = 'E:\bs_innovation';
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_classical_baselines', 'matlab'));
scope = stage8_k2_cb_add_paths(repo_dir); %#ok<NASGU>
test_trial_reconstruction_hash;
test_element_whitening_contract;
test_music_two_peak_fixture;
test_music_l1_not_applicable;
test_beamspace_cml_contains_fixed_grid;
test_summary_schema_fixture;
```

After the tested tool commit is pushed, run smoke and formal comparison once
in one uninterrupted MATLAB process:

```matlab
repo_dir = 'E:\bs_innovation';
runtime_root = ...
    'E:\bs_innovation_runtime\stage8_k2_classical_baselines_v1';
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_classical_baselines', 'matlab'));
stage8_k2_cb_run(repo_dir, runtime_root);
```

Required runtime: MATLAB R2022b with `-singleCompThread`. The runner creates no
pool, `parfor`, coordinator, scheduled task, bootstrap, or recovery framework.
If interrupted, remove only the uncommitted runtime root shown above and run
again from the beginning.
