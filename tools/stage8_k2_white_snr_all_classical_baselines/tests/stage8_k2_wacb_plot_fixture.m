function fixture = stage8_k2_wacb_plot_fixture(constants)
%STAGE8_K2_WACB_PLOT_FIXTURE Build deterministic data-only plot fixtures.

methods = constants.all_method_ids;
snrs = constants.white_snr_targets_db;
overall_rows = repmat(summary_local(), numel(methods) * numel(snrs), 1);
index = 0;
for method_index = 1:numel(methods)
    for snr = snrs
        index = index + 1;
        row = summary_local();
        row.method_id = methods(method_index);
        row.white_beamspace_snr_target_db = snr;
        row.total_count = 240;
        row.applicable_count = 200;
        row.valid_count = max(0, min(200, round(120 + 3 * snr)));
        row.structural_na_count = 40;
        row.algorithmic_invalid_count = row.applicable_count - row.valid_count;
        row.valid_rate = row.valid_count / row.applicable_count;
        row.joint_RMSE_deg_median = max(0.01, 0.5 - 0.01 * snr);
        row.joint_RMSE_deg_p90 = 1.5 * row.joint_RMSE_deg_median;
        row.runtime_sec_median = 0.1 + 0.02 * method_index;
        overall_rows(index) = row;
    end
end
overall = struct2table(overall_rows);
profile_rows = repmat(summary_local(), ...
    4 * 4 * numel(snrs), 1);
index = 0;
new_methods = constants.method_ids;
for method_index = 1:4
    for profile = constants.profile_ids.'
        for snr = snrs
            index = index + 1;
            row = summary_local();
            row.method_id = new_methods(method_index);
            row.profile_id = profile;
            row.white_beamspace_snr_target_db = snr;
            row.total_count = 60;
            row.applicable_count = double(profile ~= "P2") * 60;
            row.valid_count = round(0.6 * row.applicable_count);
            row.valid_rate = ratio_local(row.valid_count, row.applicable_count);
            profile_rows(index) = row;
        end
    end
end
profile = struct2table(profile_rows);
failure_rows = repmat(struct('method_id', "", ...
    'white_beamspace_snr_target_db', 0, 'applicability_status', "APPLICABLE", ...
    'fit_status', "FIXTURE_INVALID", 'failure_stage', "ALGORITHM_INVALID", ...
    'row_count', 1), numel(methods), 1);
for method_index = 1:numel(methods)
    failure_rows(method_index).method_id = methods(method_index);
end
failure = struct2table(failure_rows);
pairwise_rows = repmat(struct('method_id', "", ...
    'white_beamspace_snr_target_db', 0, 'paired_valid_count', 30, ...
    'new_wins', 12, 'ties', 2, 'tangent_wins', 16, ...
    'delta_rmse_new_minus_tangent_median_deg', 0.01), ...
    9 * numel(snrs), 1);
pair_methods = setdiff(methods, "TANGENT_PROFILE_SAFE", 'stable');
index = 0;
for method_index = 1:numel(pair_methods)
    for snr = snrs
        index = index + 1;
        pairwise_rows(index).method_id = pair_methods(method_index);
        pairwise_rows(index).white_beamspace_snr_target_db = snr;
    end
end
pairwise = struct2table(pairwise_rows);
complexity = overall(:, {'method_id','white_beamspace_snr_target_db', ...
    'applicable_count','runtime_sec_median'});
eigen_rows = repmat(struct('method_id', "", ...
    'white_beamspace_snr_target_db', 0, 'elevation_valid_rate', 0.6, ...
    'conditional_valid_rate', 0.7), 3 * numel(snrs), 1);
index = 0;
for method_index = 2:4
    for snr = snrs
        index = index + 1;
        eigen_rows(index).method_id = new_methods(method_index);
        eigen_rows(index).white_beamspace_snr_target_db = snr;
    end
end
eigenstructure = struct2table(eigen_rows);
representative = struct('included', true, 'trial_id', "FIXTURE", ...
    'element_music', struct('az_grid_deg', [7.4, 7.5], ...
    'el_grid_deg', [9.8, 9.9], ...
    'normalized_spectrum_db', [0, -3; -5, -10]), ...
    'gfbss', struct('applicable', true, ...
    'elevation_grid_deg', [9.8, 9.9, 10.0], ...
    'normalized_elevation_spectrum_db', [-8, 0, -6]), ...
    'root_music', struct('applicable', true, ...
    'all_roots', [0.9 + 0.1j; 0.9 - 0.1j]), ...
    'esprit', struct('applicable', true, ...
    'Psi_eigenvalues', [0.99 + 0.05j, 0.99 + 0.07j]));
fixture = struct('overall', overall, 'profile', profile, ...
    'failure', failure, 'pairwise', pairwise, ...
    'complexity', complexity, 'eigenstructure', eigenstructure, ...
    'representative_spectra', {{representative}});
end

function row = summary_local()
row = struct('method_id', "", 'white_beamspace_snr_target_db', NaN, ...
    'profile_id', "ALL", 'total_count', 0, 'applicable_count', 0, ...
    'valid_count', 0, 'structural_na_count', 0, ...
    'algorithmic_invalid_count', 0, 'valid_rate', NaN, ...
    'joint_RMSE_deg_median', NaN, 'joint_RMSE_deg_p90', NaN, ...
    'runtime_sec_median', NaN);
end

function value = ratio_local(a, b)
if b == 0, value = NaN; else, value = a / b; end
end
