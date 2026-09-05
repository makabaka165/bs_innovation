function cleanup = stage8_k2_rtc_add_paths(repo)
old = path;
cleanup = onCleanup(@() path(old));
project = fullfile(repo, 'beamspace_ml_v18', 'source', 'stepwise_signal_model');
for name = ["config", "array", "beamforming"]
    addpath(fullfile(project, 'core', name));
end
steps = ["step_12_0_receive_model_correction", "step_12_1_sequential_dbf_model", ...
    "step_12_2_stable_dml_backend", "step_12_3_grouped_conditional_dml", ...
    "step_12_4_near_pair_tangent_asymptotics", "step_12_5_exact_subset_fim_beam_design", ...
    "step_12_6_k12_bootstrap_resolution", "step_12_7_known_k_local_cell_refinement"];
for name = steps
    addpath(fullfile(project, 'steps', name, 'common'));
end
for name = ["stage8_k2_classical_baselines", "stage8_k2_subspace_baselines", ...
        "stage8_k2_raw_tangent_core_native_snr"]
    addpath(fullfile(repo, 'tools', name, 'matlab'));
end
end
