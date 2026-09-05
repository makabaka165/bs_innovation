function paths = stage8_k2_rtc_source_paths(repo)
tool = fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr');
entries = [dir(fullfile(tool,'**','*.m')); dir(fullfile(tool,'**','*.ps1'))];
project = fullfile(repo,'beamspace_ml_v18','source','stepwise_signal_model');
for category = ["core/config", "core/array", "core/beamforming"]
    entries = [entries; dir(fullfile(project,category,'*.m'))]; %#ok<AGROW>
end
for category = ["step_12_0_receive_model_correction", "step_12_1_sequential_dbf_model", ...
        "step_12_2_stable_dml_backend", "step_12_3_grouped_conditional_dml", ...
        "step_12_4_near_pair_tangent_asymptotics", "step_12_5_exact_subset_fim_beam_design", ...
        "step_12_6_k12_bootstrap_resolution", "step_12_7_known_k_local_cell_refinement"]
    entries = [entries; dir(fullfile(project,'steps',category,'common','*.m'))]; %#ok<AGROW>
end
for category = ["stage8_k2_classical_baselines", "stage8_k2_subspace_baselines"]
    entries = [entries; dir(fullfile(repo,'tools',category,'matlab','*.m'))]; %#ok<AGROW>
end
paths = cell(numel(entries),1);
for k = 1:numel(entries)
    absolute = fullfile(entries(k).folder,entries(k).name);
    paths{k} = strrep(absolute(numel(repo)+2:end),'\','/');
end
paths = sort(unique(paths));
end
