# Stage8 K2 Vincent Anchored Projector AML

Protocol: STAGE8_K2_VINCENT_ANCHORED_PROJECTOR_AML_V1

This isolated MATLAB R2022b tool evaluates a known-K=2 candidate that keeps
the frozen Core-Lite K1 center and the existing data-driven Tangent axis, but
searches an anchor coordinate along that axis. At each anchor it uses
third-order cylindrical directional derivatives and a rank-safe projector
expansion to conditionally calculate a positive close-pair rho. Exact
sequential full-manifold concentrated DML scores every final candidate.

The online result upgrades the frozen Core-Lite K2 grid only when the raw
anchored likelihood is valid and no lower than the fixed-grid likelihood.
Otherwise it returns FIXED_GRID_FALLBACK. The frozen Tangent and Full4D
results are evaluated separately and never participate in that safe selection.

Run the five tests from MATLAB R2022b using one computation thread:

    repo_dir = 'E:\bs_innovation';
    addpath(fullfile(repo_dir, 'tools', ...
        'stage8_k2_vincent_anchored_aml', 'matlab'));
    scope = stage8_k2_va_add_paths(repo_dir); %#ok<NASGU>
    test_cylindrical_directional_derivatives;
    test_projector_expansion_order;
    test_conditional_rho_synthetic_curve;
    test_anchor_parameterization_contract;
    test_one_trial_no_truth_smoke;

After the tested tool commit is pushed, run the formal experiment once:

    repo_dir = 'E:\bs_innovation';
    stage8_k2_va_run(repo_dir, ...
        'E:\bs_innovation_runtime\stage8_k2_vincent_anchored_aml_v1');

The formal runner requires MATLAB R2022b with -singleCompThread, one MATLAB
process, an empty runtime root, the pushed execution branch, unchanged frozen
paths, and no tracked local changes. It creates no pool, parfor, coordinator,
scheduled task, bootstrap, or recovery/checkpoint framework.
