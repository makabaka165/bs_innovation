# Stage8 K2 Structured Subspace Baselines

Protocol: `STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_V1`

This isolated MATLAB R2022b tool reconstructs the exact 72 evidence-31 K2
element observations, verifies every frozen element hash, and adds three
classical element-domain references:

- generalized vertical FBSS-MUSIC plus conditional azimuth CML;
- white-noise vertical FBSS Root-MUSIC plus conditional azimuth CML;
- white-noise vertical FBSS LS-ESPRIT plus conditional azimuth CML.

The methods use the exact vertical ULA structure of the active 32-by-65
cylindrical subarray. They are more-informative element-domain references, not
15-dimensional beamspace replacements. Tangent, Full4D CML, standard MUSIC,
profiles, seeds, and evidence 31-34 are read-only.

Run the ten fixed tests in one MATLAB R2022b process with one computation
thread:

```matlab
repo_dir = 'E:\bs_innovation';
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_classical_baselines', 'matlab'));
scope = stage8_k2_cb_add_paths(repo_dir); %#ok<NASGU>
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_subspace_baselines', 'matlab'));
stage8_k2_sb_run_tests(repo_dir);
```

After the tested tool commit is pushed, run smoke and the complete formal
comparison once in a fresh MATLAB R2022b `-singleCompThread` process:

```matlab
repo_dir = 'E:\bs_innovation';
runtime_root = ...
    'E:\bs_innovation_runtime\stage8_k2_subspace_baselines_v1';
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_classical_baselines', 'matlab'));
scope = stage8_k2_cb_add_paths(repo_dir); %#ok<NASGU>
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_subspace_baselines', 'matlab'));
stage8_k2_sb_run(repo_dir, runtime_root);
```

The runner creates no pool, `parfor`, coordinator, scheduled task, bootstrap,
or checkpoint framework. If interrupted, remove only the exact uncommitted
runtime root above and restart from the beginning.
