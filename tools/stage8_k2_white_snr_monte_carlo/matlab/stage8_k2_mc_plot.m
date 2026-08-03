function paths = stage8_k2_mc_plot( ...
    summary, profile_summary, snr_rows, figure_dir, constants)
%STAGE8_K2_MC_PLOT Generate the five registered paper figures.

if ~isfolder(figure_dir) && ~mkdir(figure_dir)
    error('stage8_k2_mc_plot:Directory', ...
        'Unable to create figure output directory.');
end
paths = struct( ...
    'rmse', fullfile(figure_dir, '44_white_snr_rmse_curve.png'), ...
    'fallback', fullfile(figure_dir, '44_white_snr_fallback_curve.png'), ...
    'pairwise', fullfile(figure_dir, '44_white_snr_pairwise_curve.png'), ...
    'profile', fullfile(figure_dir, '44_white_snr_profile_curve.png'), ...
    'projected', fullfile(figure_dir, ...
    '44_projected_snr_profile_distribution.png'));

targets = constants.white_snr_targets_db;
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 560]);
hold on;
for method = reshape(constants.method_ids, 1, [])
    rows = summary(summary.row_type == "METHOD" & ...
        summary.scope_type == "SNR" & summary.method_id == method, :);
    rows = sortrows(rows, 'white_beamspace_snr_target_db');
    plot(rows.white_beamspace_snr_target_db, ...
        rows.median_joint_RMSE_deg, '-o', 'LineWidth', 1.5, ...
        'DisplayName', char(method + " median"));
    plot(rows.white_beamspace_snr_target_db, ...
        rows.p90_joint_RMSE_deg, '--', 'LineWidth', 1.2, ...
        'DisplayName', char(method + " P90"));
end
xlabel('Whitened sequential-beamspace expected total SNR (dB)');
ylabel('Joint RMSE (deg)'); grid on; xticks(targets);
legend('Location', 'northeastoutside');
title('Stage8 K2 joint RMSE by white SNR');
exportgraphics(fig, paths.rmse, 'Resolution', 180); close(fig);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 820 520]);
rows = summary(summary.row_type == "METHOD" & ...
    summary.scope_type == "SNR" & ...
    summary.method_id == "TANGENT_PROFILE_SAFE", :);
rows = sortrows(rows, 'white_beamspace_snr_target_db');
plot(rows.white_beamspace_snr_target_db, rows.fallback_rate, ...
    '-o', 'LineWidth', 1.5, 'DisplayName', 'Fallback rate'); hold on;
plot(rows.white_beamspace_snr_target_db, rows.upgrade_rate, ...
    '-s', 'LineWidth', 1.5, 'DisplayName', 'Raw-upgrade rate');
xlabel('Whitened sequential-beamspace expected total SNR (dB)');
ylabel('Rate'); ylim([0 1]); xticks(targets); grid on; legend('Location','best');
title('Tangent fallback and raw-upgrade rates');
exportgraphics(fig, paths.fallback, 'Resolution', 180); close(fig);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 680]);
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
references = ["CORE_LITE", "CORE_PLUS"];
for index = 1:2
    nexttile(layout); hold on;
    rows = summary(summary.row_type == "PAIRWISE" & ...
        summary.scope_type == "SNR" & ...
        summary.reference_method_id == references(index), :);
    rows = sortrows(rows, 'white_beamspace_snr_target_db');
    plot(rows.white_beamspace_snr_target_db, rows.wins, '-o', ...
        'LineWidth', 1.4, 'DisplayName', 'Wins');
    plot(rows.white_beamspace_snr_target_db, rows.ties, '-s', ...
        'LineWidth', 1.4, 'DisplayName', 'Ties');
    plot(rows.white_beamspace_snr_target_db, rows.losses, '-^', ...
        'LineWidth', 1.4, 'DisplayName', 'Losses');
    ylabel('Paired count'); xticks(targets); grid on;
    title(sprintf('Tangent vs %s', references(index)));
    legend('Location','best');
end
xlabel(layout, 'Whitened sequential-beamspace expected total SNR (dB)');
exportgraphics(fig, paths.pairwise, 'Resolution', 180); close(fig);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 560]);
hold on;
for profile = reshape(constants.profile_ids, 1, [])
    rows = profile_summary(profile_summary.row_type == "METHOD" & ...
        profile_summary.method_id == "TANGENT_PROFILE_SAFE" & ...
        endsWith(profile_summary.scope_value, "|" + profile), :);
    rows = sortrows(rows, 'white_beamspace_snr_target_db');
    plot(rows.white_beamspace_snr_target_db, ...
        rows.median_joint_RMSE_deg, '-o', 'LineWidth', 1.5, ...
        'DisplayName', char(profile + " median"));
    plot(rows.white_beamspace_snr_target_db, ...
        rows.p90_joint_RMSE_deg, '--', 'LineWidth', 1.1, ...
        'DisplayName', char(profile + " P90"));
end
xlabel('Whitened sequential-beamspace expected total SNR (dB)');
ylabel('Tangent joint RMSE (deg)'); xticks(targets); grid on;
legend('Location','northeastoutside');
title('Tangent profile operating curves');
exportgraphics(fig, paths.profile, 'Resolution', 180); close(fig);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 820 520]);
boxchart(categorical(snr_rows.profile_id, constants.profile_ids), ...
    snr_rows.k2_projected_snr_expected_db);
xlabel('Profile'); ylabel('K2 projected expected SNR (dB)'); grid on;
title('Truth-only projected K2 SNR by profile');
exportgraphics(fig, paths.projected, 'Resolution', 180); close(fig);

names = fieldnames(paths);
for index = 1:numel(names)
    info = dir(paths.(names{index}));
    if isempty(info) || info.bytes == 0
        error('stage8_k2_mc_plot:Output', ...
            'A registered figure was not written.');
    end
end
end
