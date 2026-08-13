# Stage8 K2 Tangent-Profile Experiment

Protocol: `STAGE8_K2_TANGENT_PROFILE_DECISIVE_EXPERIMENT_V1`

This isolated tool evaluates one known-K K2 candidate without changing the
frozen Step12.7 production interface. It obtains a center from the frozen
Core-Lite K1 path, estimates one projected-residual direction with the
registered Fisher metric, profiles one positive separation scale with the
exact full sequential manifold, and selects safely against the frozen
Core-Lite fixed-grid K2 result.

Run the four theory tests from MATLAB R2022b with one computation thread:

```matlab
repo_dir = 'E:\bs_innovation';
addpath(fullfile(repo_dir, 'tools', 'stage8_k2_tangent_profile', 'matlab'));
scope = stage8_k2_tp_add_paths(repo_dir); %#ok<NASGU>
test_tangent_direction_noiseless;
test_tangent_direction_noise_shift;
test_tangent_rank_deficiency;
test_one_trial_full_manifold_smoke;
```

After committing and pushing the tested tool, run the complete experiment in
one uninterrupted MATLAB session:

```matlab
repo_dir = 'E:\bs_innovation';
addpath(fullfile(repo_dir, 'tools', 'stage8_k2_tangent_profile', 'matlab'));
stage8_k2_tp_run_experiment(repo_dir, ...
    'E:\bs_innovation_runtime\stage8_k2_tangent_profile_v1');
```

Required runtime: MATLAB R2022b with `-singleCompThread`. The tool does not
create a pool, worker, coordinator, scheduled task, checkpoint, bootstrap,
or automatic-K decision.
