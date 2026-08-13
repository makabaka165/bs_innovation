function figure_paths = stage8_k2_wacb_plot_from_committed_data( ...
    repo_dir, data_dir, output_dir)
%STAGE8_K2_WACB_PLOT_FROM_COMMITTED_DATA Replot without estimator calls.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_wacb_plot_from_committed_data:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
if nargin < 2 || isempty(data_dir)
    data_dir = fullfile(repo_dir, 'innovation-mining');
end
if nargin < 3 || isempty(output_dir)
    output_dir = fullfile(repo_dir, 'innovation-mining', 'figures');
end
if ~isfolder(output_dir) && ~mkdir(output_dir)
    error('stage8_k2_wacb_plot_from_committed_data:Output', ...
        'Unable to create plot output directory.');
end
paths = struct( ...
    'overall', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_all_method_summary.csv'), ...
    'profile', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_all_method_profile_summary.csv'), ...
    'failure', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_all_method_failure_summary.csv'), ...
    'pairwise', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_all_method_pairwise_vs_tangent.csv'), ...
    'complexity', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_all_method_complexity_summary.csv'), ...
    'eigen', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_subspace_eigenstructure_summary.csv'), ...
    'spectra', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_representative_spectra.mat'), ...
    'manifest', fullfile(data_dir, ...
    '48_stage8_k2_white_snr_plot_data_manifest.json'));
required = struct2cell(paths);
if ~all(cellfun(@isfile, required))
    error('stage8_k2_wacb_plot_from_committed_data:Missing', ...
        'One or more committed plot-data inputs are missing.');
end
overall = readtable(paths.overall, 'TextType', 'string');
profile = readtable(paths.profile, 'TextType', 'string');
failure = readtable(paths.failure, 'TextType', 'string');
pairwise = readtable(paths.pairwise, 'TextType', 'string');
complexity = readtable(paths.complexity, 'TextType', 'string');
eigenstructure = readtable(paths.eigen, 'TextType', 'string');
loaded = load(paths.spectra, 'representative_spectra', '-mat');
jsondecode(fileread(paths.manifest));
if ~isfield(loaded, 'representative_spectra')
    error('stage8_k2_wacb_plot_from_committed_data:SpectraSchema', ...
        'Representative spectra variable is missing.');
end

names = [ ...
    "48_white_snr_all_method_valid_rate.png"; ...
    "48_white_snr_all_method_joint_rmse_median.png"; ...
    "48_white_snr_all_method_joint_rmse_p90.png"; ...
    "48_white_snr_subspace_elevation_valid_rate.png"; ...
    "48_white_snr_conditional_az_cml_valid_rate.png"; ...
    "48_white_snr_failure_reason_stack.png"; ...
    "48_white_snr_runtime_complexity.png"; ...
    "48_white_snr_pairwise_vs_tangent.png"; ...
    "48_white_snr_profile_valid_rate.png"; ...
    "48_white_snr_element_music_representative_spectra.png"; ...
    "48_white_snr_gfbss_representative_spectra.png"; ...
    "48_white_snr_root_esprit_diagnostics.png"];
figure_paths = strings(numel(names), 1);
for index = 1:numel(names)
    figure_paths(index) = string(fullfile(output_dir, names(index)));
end

make_line_figure_local(overall, 'valid_rate', 'Valid rate', ...
    'Valid rate among applicable rows', figure_paths(1));
make_line_figure_local(overall, 'joint_RMSE_deg_median', ...
    'Joint RMSE median (deg)', 'Conditional median RMSE and valid output', ...
    figure_paths(2));
make_line_figure_local(overall, 'joint_RMSE_deg_p90', ...
    'Joint RMSE P90 (deg)', 'Conditional P90 RMSE and valid output', ...
    figure_paths(3));
make_line_figure_local(eigenstructure, 'elevation_valid_rate', ...
    'Elevation-stage valid rate', 'Vertical subspace elevation validity', ...
    figure_paths(4));
make_line_figure_local(eigenstructure, 'conditional_valid_rate', ...
    'Conditional azimuth valid rate', ...
    'Conditional azimuth CML validity after execution', figure_paths(5));
make_failure_local(failure, figure_paths(6));
make_line_figure_local(complexity, 'runtime_sec_median', ...
    'Median runtime (s)', 'Runtime by registered method', figure_paths(7));
make_pairwise_local(pairwise, figure_paths(8));
make_profile_local(profile, figure_paths(9));
make_representative_local(loaded.representative_spectra, ...
    figure_paths(10), figure_paths(11), figure_paths(12));
end

function make_line_figure_local(data, variable, y_label, title_text, path_now)
figure_now = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100, 100, 1050, 620]);
cleanup = onCleanup(@() close(figure_now));
hold on;
methods = unique(data.method_id, 'stable');
for index = 1:numel(methods)
    selected = data(data.method_id == methods(index), :);
    selected = sortrows(selected, 'white_beamspace_snr_target_db');
    plot(selected.white_beamspace_snr_target_db, selected.(variable), ...
        '-o', 'LineWidth', 1.2, 'MarkerSize', 4, ...
        'DisplayName', short_label_local(methods(index)));
end
hold off; grid on; box on;
xlabel('Expected white sequential-beamspace SNR (dB)');
ylabel(y_label); title(title_text);
legend('Location', 'eastoutside', 'Interpreter', 'none');
exportgraphics(figure_now, path_now, 'Resolution', 160);
clear cleanup
end

function make_failure_local(data, path_now)
methods = unique(data.method_id, 'stable');
structural = zeros(numel(methods), 1);
invalid = zeros(numel(methods), 1);
for index = 1:numel(methods)
    selected = data(data.method_id == methods(index), :);
    structural(index) = sum(selected.row_count( ...
        selected.failure_stage == "STRUCTURAL_NA"));
    invalid(index) = sum(selected.row_count( ...
        selected.failure_stage ~= "STRUCTURAL_NA" & ...
        selected.failure_stage ~= "NONE"));
end
figure_now = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100, 100, 1100, 600]);
cleanup = onCleanup(@() close(figure_now));
bar([structural, invalid], 'stacked'); grid on; box on;
xticks(1:numel(methods)); xticklabels(short_label_local(methods));
xtickangle(35); ylabel('Row count');
legend({'Structural N/A','Algorithmic invalid'}, 'Location', 'northwest');
title('Structural N/A is separated from estimator failure');
exportgraphics(figure_now, path_now, 'Resolution', 160);
clear cleanup
end

function make_pairwise_local(data, path_now)
methods = unique(data.method_id, 'stable');
wins = zeros(numel(methods), 1);
losses = zeros(numel(methods), 1);
ties = zeros(numel(methods), 1);
for index = 1:numel(methods)
    selected = data(data.method_id == methods(index), :);
    wins(index) = sum(selected.new_wins);
    losses(index) = sum(selected.tangent_wins);
    ties(index) = sum(selected.ties);
end
figure_now = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100, 100, 1050, 600]);
cleanup = onCleanup(@() close(figure_now));
bar([wins, ties, losses]); grid on; box on;
xticks(1:numel(methods)); xticklabels(short_label_local(methods));
xtickangle(35); ylabel('Common-valid trial count');
legend({'Method wins','Ties','Tangent wins'}, 'Location', 'northwest');
title('Paired RMSE comparison on common-valid trials only');
exportgraphics(figure_now, path_now, 'Resolution', 160);
clear cleanup
end

function make_profile_local(data, path_now)
methods = ["ELEMENT_MUSIC_K2"; ...
    "ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML"; ...
    "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML"; ...
    "ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML"];
figure_now = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100, 100, 1100, 760]);
cleanup = onCleanup(@() close(figure_now));
layout = tiledlayout(2, 2, 'TileSpacing', 'compact');
for method_index = 1:numel(methods)
    nexttile; hold on;
    for profile_id = ["P1","P2","P3","P4"]
        selected = data(data.method_id == methods(method_index) & ...
            data.profile_id == profile_id, :);
        selected = sortrows(selected, 'white_beamspace_snr_target_db');
        plot(selected.white_beamspace_snr_target_db, selected.valid_rate, ...
            '-o', 'DisplayName', profile_id);
    end
    hold off; grid on; ylim([0, 1]);
    title(short_label_local(methods(method_index)), 'Interpreter', 'none');
    xlabel('White SNR (dB)'); ylabel('Valid rate');
end
legend(layout.Children(end), 'Location', 'best');
title(layout, 'Profile-specific valid rates; P2 structural N/A retained');
exportgraphics(figure_now, path_now, 'Resolution', 160);
clear cleanup
end

function make_representative_local(spectra, element_path, gfbss_path, root_path)
element_item = first_local(spectra, @(item) item.included);
figure_now = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100, 100, 900, 650]);
cleanup = onCleanup(@() close(figure_now));
imagesc(element_item.element_music.az_grid_deg, ...
    element_item.element_music.el_grid_deg, ...
    element_item.element_music.normalized_spectrum_db.');
axis xy; colorbar; caxis([-40, 0]);
xlabel('Azimuth (deg)'); ylabel('Elevation (deg)');
title('Representative Element MUSIC spectrum (dB)');
exportgraphics(figure_now, element_path, 'Resolution', 160);
clear cleanup

gfbss_item = first_local(spectra, @(item) item.gfbss.applicable);
figure_now = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100, 100, 900, 560]);
cleanup = onCleanup(@() close(figure_now));
plot(gfbss_item.gfbss.elevation_grid_deg, ...
    gfbss_item.gfbss.normalized_elevation_spectrum_db, 'LineWidth', 1.4);
grid on; xlabel('Elevation (deg)'); ylabel('Normalized spectrum (dB)');
title('Representative GFBSS-MUSIC elevation spectrum');
exportgraphics(figure_now, gfbss_path, 'Resolution', 160);
clear cleanup

root_item = first_local(spectra, @(item) item.root_music.applicable);
figure_now = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100, 100, 1000, 500]);
cleanup = onCleanup(@() close(figure_now));
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile;
roots_now = root_item.root_music.all_roots;
plot(real(roots_now), imag(roots_now), '.', 'MarkerSize', 8); hold on;
theta = linspace(0, 2*pi, 400);
plot(cos(theta), sin(theta), 'k-'); hold off; axis equal; grid on;
xlabel('Real'); ylabel('Imaginary'); title('Root-MUSIC roots');
nexttile;
eigenvalues = root_item.esprit.Psi_eigenvalues;
plot(real(eigenvalues), imag(eigenvalues), 'o', 'MarkerSize', 8); hold on;
plot(cos(theta), sin(theta), 'k-'); hold off; axis equal; grid on;
xlabel('Real'); ylabel('Imaginary'); title('LS-ESPRIT eigenvalues');
exportgraphics(figure_now, root_path, 'Resolution', 160);
clear cleanup
end

function item = first_local(items, predicate)
for index = 1:numel(items)
    if predicate(items{index})
        item = items{index};
        return;
    end
end
error('stage8_k2_wacb_plot_from_committed_data:Representative', ...
    'No representative payload satisfies the plot selector.');
end

function labels = short_label_local(methods)
labels = replace(string(methods), ...
    ["FULL4D_BEAMSPACE_CML_MULTISTART", ...
    "FULL4D_ELEMENT_CML_MULTISTART", "BEAMSPACE_MUSIC_K2", ...
    "ELEMENT_MUSIC_K2", "ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML", ...
    "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML", ...
    "ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML", ...
    "TANGENT_PROFILE_SAFE"], ...
    ["Full4D beam", "Full4D element", "Beam MUSIC", "Element MUSIC", ...
    "GFBSS + az CML", "Root-MUSIC + az CML", ...
    "LS-ESPRIT + az CML", "Tangent"]);
end
