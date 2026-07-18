function gap = build_stage7_greedy_gap_table(operating, greedy_rows)
%BUILD_STAGE7_GREEDY_GAP_TABLE Compare heuristic and exact finite-family optima.

gap = greedy_rows;
gap.exact_subset_id = strings(height(gap), 1);
gap.same_subset_flag = false(height(gap), 1);
gap.cost_gap = NaN(height(gap), 1);
gap.eta_gap = NaN(height(gap), 1);
gap.exact_MAC_total = NaN(height(gap), 1);
gap.exact_eta_design = NaN(height(gap), 1);
for index = 1:height(gap)
    exact = operating(abs(operating.eta0 - gap.eta0(index)) < 1e-12, :);
    gap.exact_subset_id(index) = exact.subset_id;
    gap.same_subset_flag(index) = gap.subset_id(index) == exact.subset_id;
    gap.cost_gap(index) = gap.MAC_total(index) - exact.MAC_total;
    gap.eta_gap(index) = gap.eta_design(index) - exact.eta_design;
    gap.exact_MAC_total(index) = exact.MAC_total;
    gap.exact_eta_design(index) = exact.eta_design;
end
end
