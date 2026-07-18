function outputs = plot_stage7_results(figure_dir, enumeration, operating, ...
    greedy_gap, threshold_summary, risk)
%PLOT_STAGE7_RESULTS Generate the eight registered Stage 7 figures.

if exist(figure_dir, 'dir') ~= 7, mkdir(figure_dir); end
outputs = struct();
outputs.eta_mac = fullfile(figure_dir, 'eta_vs_mac_pareto.png');
outputs.eta_channels = fullfile(figure_dir, 'eta_vs_output_channels.png');
outputs.crb_cost = fullfile(figure_dir, 'crb_inflation_vs_cost.png');
outputs.greedy_gap = fullfile(figure_dir, 'greedy_exact_gap.png');
outputs.success_snr = fullfile(figure_dir, 'success_vs_snr.png');
outputs.wrong_snr = fullfile(figure_dir, 'wrong_peak_vs_snr.png');
outputs.fim_risk = fullfile(figure_dir, 'fim_vs_finite_sample_risk.png');
outputs.layouts = fullfile(figure_dir, 'selected_beam_layouts.png');

figure('Visible','off','Color','w');
scatter(enumeration.MAC_total, enumeration.eta_design, 16, ...
    enumeration.B_out, 'filled'); hold on;
scatter(operating.MAC_total, operating.eta_design, 70, 'k', 'x', 'LineWidth', 1.5);
xlabel('Complex MAC per sample'); ylabel('Worst-case design eta'); grid on; colorbar;
exportgraphics(gcf, outputs.eta_mac, 'Resolution', 180); close(gcf);

figure('Visible','off','Color','w');
scatter(enumeration.B_out, enumeration.eta_design, 18, enumeration.MAC_total, 'filled');
xlabel('Output channels'); ylabel('Worst-case design eta'); grid on; colorbar;
exportgraphics(gcf, outputs.eta_channels, 'Resolution', 180); close(gcf);

figure('Visible','off','Color','w');
valid = enumeration.eta_design > 0;
scatter(enumeration.MAC_total(valid), 1 ./ enumeration.eta_design(valid), ...
    16, enumeration.B_out(valid), 'filled');
xlabel('Complex MAC per sample'); ylabel('Predicted CRB inflation ceiling');
grid on; colorbar; ylim([1, max(2, min(10, max(1 ./ enumeration.eta_design(valid))))]);
exportgraphics(gcf, outputs.crb_cost, 'Resolution', 180); close(gcf);

figure('Visible','off','Color','w');
yyaxis left; bar(greedy_gap.eta0, greedy_gap.cost_gap, 0.35); ylabel('MAC cost gap');
yyaxis right; plot(greedy_gap.eta0, greedy_gap.eta_gap, '-o', 'LineWidth', 1.4);
ylabel('eta gap'); xlabel('eta operating point'); grid on;
exportgraphics(gcf, outputs.greedy_gap, 'Resolution', 180); close(gcf);

plot_threshold_local(threshold_summary, 'oracle_k_success_rate', ...
    'Oracle-K success rate', outputs.success_snr);
plot_threshold_local(threshold_summary, 'wrong_local_peak_rate', ...
    'Wrong-local-peak rate', outputs.wrong_snr);

figure('Visible','off','Color','w');
scatter(risk.eta_design, risk.oracle_k_success_rate, 45, risk.MAC_total, 'filled');
xlabel('Worst-case design eta'); ylabel('Finite-sample success rate');
grid on; colorbar;
exportgraphics(gcf, outputs.fim_risk, 'Resolution', 180); close(gcf);

figure('Visible','off','Color','w','Position',[100,100,1000,320]);
for index = 1:height(operating)
    subplot(1, height(operating), index);
    image_data = zeros(5);
    if ~isfinite(operating.elevation_mask_integer(index)) || ...
            ~isfinite(operating.azimuth_mask_integer(index))
        axis off;
        text(0.5, 0.5, sprintf('eta=%.2f\ninfeasible', ...
            operating.eta0(index)), 'HorizontalAlignment', 'center');
        continue;
    end
    elevation = logical(bitget(operating.elevation_mask_integer(index), 1:5));
    azimuth = logical(bitget(operating.azimuth_mask_integer(index), 1:5));
    image_data(elevation, azimuth) = 1;
    imagesc(image_data); axis image; set(gca, 'YDir', 'normal');
    xticks(1:5); yticks(1:5); clim([0,1]);
    title(sprintf('eta=%.2f, %dx%d', operating.eta0(index), ...
        operating.B_e(index), operating.B_a(index)));
    xlabel('Azimuth beam ID'); ylabel('Elevation beam ID');
end
colormap([0.92,0.92,0.92;0.12,0.45,0.70]);
exportgraphics(gcf, outputs.layouts, 'Resolution', 180); close(gcf);
end

function plot_threshold_local(summary, field_name, y_label, path_out)
figure('Visible','off','Color','w'); hold on;
selected_methods = ["FULL_PARENT_5X5";"FIXED_RECT_3X5"; ...
    "FIXED_RECT_5X3";"EXACT_ETA_080";"EXACT_ETA_090";"EXACT_ETA_095"];
for method_index = 1:numel(selected_methods)
    rows = summary(summary.method_id == selected_methods(method_index), :);
    if isempty(rows), continue; end
    rows = sortrows(rows, {'threshold_profile','element_snr_db'});
    profiles = unique(rows.threshold_profile, 'stable');
    for profile_index = 1:numel(profiles)
        now = rows(rows.threshold_profile == profiles(profile_index), :);
        plot(now.element_snr_db, now.(field_name), '-o', 'LineWidth', 1.1, ...
            'DisplayName', char(selected_methods(method_index) + " " + ...
            profiles(profile_index)));
    end
end
xlabel('Element-domain SNR (dB)'); ylabel(y_label); grid on;
legend('Location','eastoutside','Interpreter','none'); ylim([0,1]);
exportgraphics(gcf, path_out, 'Resolution', 180); close(gcf);
end
