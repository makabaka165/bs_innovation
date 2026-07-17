function [result_table, plot_info] = test_receive_beamwidth_comparison( ...
    x, y, z, lambda, steer_az_deg, steer_el_deg, figure_path)
%TEST_RECEIVE_BEAMWIDTH_COMPARISON Compare active and legacy model widths.

scan_step_deg = 0.002;
az_scan_deg = (steer_az_deg - 8):scan_step_deg:(steer_az_deg + 8);
el_scan_deg = (steer_el_deg - 12):scan_step_deg:(steer_el_deg + 12);
comparison_factors = [1, 2];
model_role = ["active_receive", "legacy_comparison"];

az_response_db = zeros(numel(comparison_factors), numel(az_scan_deg));
el_response_db = zeros(numel(comparison_factors), numel(el_scan_deg));
beamwidth_3db_deg = zeros(4, 1);
left_3db_deg = zeros(4, 1);
right_3db_deg = zeros(4, 1);
peak_angle_deg = zeros(4, 1);
peak_offset_deg = zeros(4, 1);
cut_name = strings(4, 1);
role_column = strings(4, 1);
comparison_model_phase_factor = zeros(4, 1);
phase_factor = ones(4, 1);
pass_flag = false(4, 1);

row = 0;
for iModel = 1:numel(comparison_factors)
    model_factor = comparison_factors(iModel);
    if model_factor == 1
        a_center = build_receive_cyl_steering_vec( ...
            x, y, z, steer_az_deg, steer_el_deg, lambda);
    else
        a_center = build_legacy_factor2_comparison_local( ...
            x, y, z, steer_az_deg, steer_el_deg, lambda);
    end
    w = a_center / norm(a_center);
    az_response = scan_response_local(x, y, z, lambda, w, az_scan_deg, ...
        steer_az_deg, steer_el_deg, 'azimuth', model_factor);
    el_response = scan_response_local(x, y, z, lambda, w, el_scan_deg, ...
        steer_az_deg, steer_el_deg, 'elevation', model_factor);
    az_response_db(iModel, :) = 20*log10(max(az_response, realmin));
    el_response_db(iModel, :) = 20*log10(max(el_response, realmin));

    [az_width, az_left, az_right, az_peak] = ...
        measure_3db_width_local(az_scan_deg, az_response);
    [el_width, el_left, el_right, el_peak] = ...
        measure_3db_width_local(el_scan_deg, el_response);
    values = [az_width, az_left, az_right, az_peak, az_peak - steer_az_deg; ...
              el_width, el_left, el_right, el_peak, el_peak - steer_el_deg];
    cuts = ["azimuth"; "elevation"];
    centers = [steer_az_deg; steer_el_deg];
    for iCut = 1:2
        row = row + 1;
        beamwidth_3db_deg(row) = values(iCut, 1);
        left_3db_deg(row) = values(iCut, 2);
        right_3db_deg(row) = values(iCut, 3);
        peak_angle_deg(row) = values(iCut, 4);
        peak_offset_deg(row) = values(iCut, 5);
        cut_name(row) = cuts(iCut);
        role_column(row) = model_role(iModel);
        comparison_model_phase_factor(row) = model_factor;
        pass_flag(row) = isfinite(values(iCut, 1)) && values(iCut, 1) > 0 && ...
            abs(values(iCut, 4) - centers(iCut)) <= scan_step_deg;
    end
end

active_az_width = beamwidth_3db_deg(role_column == "active_receive" & cut_name == "azimuth");
legacy_az_width = beamwidth_3db_deg(role_column == "legacy_comparison" & cut_name == "azimuth");
active_el_width = beamwidth_3db_deg(role_column == "active_receive" & cut_name == "elevation");
legacy_el_width = beamwidth_3db_deg(role_column == "legacy_comparison" & cut_name == "elevation");
assert(active_az_width > legacy_az_width && active_el_width > legacy_el_width, ...
    'test_receive_beamwidth_comparison:WidthOrdering', ...
    'The factor-1 beam must be wider than the isolated factor-2 comparison.');

steer_az_column_deg = repmat(steer_az_deg, 4, 1);
steer_el_column_deg = repmat(steer_el_deg, 4, 1);
scan_step_column_deg = repmat(scan_step_deg, 4, 1);
result_table = table(phase_factor, role_column, comparison_model_phase_factor, ...
    cut_name, steer_az_column_deg, steer_el_column_deg, scan_step_column_deg, ...
    beamwidth_3db_deg, left_3db_deg, right_3db_deg, peak_angle_deg, ...
    peak_offset_deg, pass_flag);
assert(all(pass_flag), 'test_receive_beamwidth_comparison:PatternFailed', ...
    'At least one pattern cut failed the width or peak check.');

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 1200, 480]);
t = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(t, 1);
plot(az_scan_deg, az_response_db(1, :), 'LineWidth', 1.8); hold on;
plot(az_scan_deg, az_response_db(2, :), '--', 'LineWidth', 1.6);
yline(-3.01029995664, ':', 'Half-power', 'LineWidth', 1.0);
grid on; ylim([-45, 1]); xlim([az_scan_deg(1), az_scan_deg(end)]);
xlabel('Azimuth (deg)'); ylabel('Normalized response (dB)');
title(sprintf('Azimuth cut at el = %.1f deg', steer_el_deg));
legend('Active receive factor 1', 'Legacy comparison factor 2', 'Location', 'southwest');
nexttile(t, 2);
plot(el_scan_deg, el_response_db(1, :), 'LineWidth', 1.8); hold on;
plot(el_scan_deg, el_response_db(2, :), '--', 'LineWidth', 1.6);
yline(-3.01029995664, ':', 'Half-power', 'LineWidth', 1.0);
grid on; ylim([-45, 1]); xlim([el_scan_deg(1), el_scan_deg(end)]);
xlabel('Elevation (deg)'); ylabel('Normalized response (dB)');
title(sprintf('Elevation cut at az = %.1f deg', steer_az_deg));
legend('Active receive factor 1', 'Legacy comparison factor 2', 'Location', 'southwest');
if exist('exportgraphics', 'file') == 2
    exportgraphics(fig, figure_path, 'Resolution', 180);
else
    print(fig, figure_path, '-dpng', '-r180');
end
close(fig);

plot_info = struct();
plot_info.figure_path = figure_path;
plot_info.active_az_width_deg = active_az_width;
plot_info.legacy_az_width_deg = legacy_az_width;
plot_info.active_el_width_deg = active_el_width;
plot_info.legacy_el_width_deg = legacy_el_width;
plot_info.az_width_ratio = active_az_width / legacy_az_width;
plot_info.el_width_ratio = active_el_width / legacy_el_width;
plot_info.num_pattern_scan_angle_evaluations = ...
    numel(comparison_factors) * (numel(az_scan_deg) + numel(el_scan_deg));
plot_info.scan_chunk_size = chunk_size_for_metadata_local();
end

function response = scan_response_local(x, y, z, lambda, w, scan_deg, ...
    steer_az_deg, steer_el_deg, cut_name, model_factor)
xv = x(:);
yv = y(:);
zv = z(:);
response = zeros(1, numel(scan_deg));
chunk_size = 256;
k0 = model_factor * 2*pi/lambda;
for iStart = 1:chunk_size:numel(scan_deg)
    idx = iStart:min(iStart + chunk_size - 1, numel(scan_deg));
    angle_deg = scan_deg(idx);
    switch cut_name
        case 'azimuth'
            ux = cosd(steer_el_deg) .* cosd(angle_deg);
            uy = cosd(steer_el_deg) .* sind(angle_deg);
            uz = sind(steer_el_deg) .* ones(size(angle_deg));
        case 'elevation'
            ux = cosd(angle_deg) .* cosd(steer_az_deg);
            uy = cosd(angle_deg) .* sind(steer_az_deg);
            uz = sind(angle_deg);
        otherwise
            error('test_receive_beamwidth_comparison:UnknownCut', ...
                'Unknown pattern cut: %s', cut_name);
    end
    phase = xv * ux + yv * uy + zv * uz;
    manifold = exp(1j * k0 * phase);
    response(idx) = abs(w' * manifold);
end
response = response / max(response);
end

function [width_deg, left_deg, right_deg, peak_deg] = ...
    measure_3db_width_local(scan_deg, response)
power_response = response.^2;
[~, peak_idx] = max(power_response);
threshold = 0.5;
left_below_idx = find(power_response(1:peak_idx) < threshold, 1, 'last');
right_relative_idx = find(power_response(peak_idx:end) < threshold, 1, 'first');
if isempty(left_below_idx) || isempty(right_relative_idx)
    error('test_receive_beamwidth_comparison:ScanTooNarrow', ...
        'The pattern scan does not contain both half-power crossings.');
end
right_below_idx = peak_idx + right_relative_idx - 1;
left_deg = interpolate_crossing_local(scan_deg(left_below_idx), ...
    scan_deg(left_below_idx + 1), power_response(left_below_idx), ...
    power_response(left_below_idx + 1), threshold);
right_deg = interpolate_crossing_local(scan_deg(right_below_idx - 1), ...
    scan_deg(right_below_idx), power_response(right_below_idx - 1), ...
    power_response(right_below_idx), threshold);
width_deg = right_deg - left_deg;
peak_deg = scan_deg(peak_idx);
end

function x_cross = interpolate_crossing_local(x1, x2, y1, y2, threshold)
if y2 == y1
    x_cross = 0.5 * (x1 + x2);
else
    x_cross = x1 + (threshold - y1) * (x2 - x1) / (y2 - y1);
end
end

function a = build_legacy_factor2_comparison_local(x, y, z, az_deg, el_deg, lambda)
% Test-only legacy reference. It is not an active Step12 manifold entry point.
ux = cosd(el_deg) * cosd(az_deg);
uy = cosd(el_deg) * sind(az_deg);
uz = sind(el_deg);
phase = x(:) * ux + y(:) * uy + z(:) * uz;
a = exp(1j * 2 * 2*pi/lambda * phase);
end

function value = chunk_size_for_metadata_local()
value = 256;
end
