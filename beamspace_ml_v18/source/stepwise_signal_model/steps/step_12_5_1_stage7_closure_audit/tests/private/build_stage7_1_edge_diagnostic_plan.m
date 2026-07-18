function [plan, plan_hash] = build_stage7_1_edge_diagnostic_plan(result_dir)
%BUILD_STAGE7_1_EDGE_DIAGNOSTIC_PLAN Freeze post-hoc edge scenarios only.

if isstring(result_dir), result_dir = char(result_dir); end
if ~(ischar(result_dir) && isrow(result_dir) && exist(result_dir, 'dir') == 7)
    error('build_stage7_1_edge_diagnostic_plan:ResultDir', ...
        'result_dir must identify the Stage 7 results directory.');
end
scenario_id = ["D0318";"V0014";"H0057"; ...
    "D0286";"V0050";"H0230"];
diagnostic_profile = [repmat("CENTRAL_3_BY_5", 3, 1); ...
    repmat("SHIFTED_3_BY_5", 3, 1)];
source_file = ["stage7_design_scenarios.csv"; ...
    "stage7_validation_scenarios.csv"; ...
    "stage7_fim_holdout_scenarios.csv"; ...
    "stage7_design_scenarios.csv"; ...
    "stage7_validation_scenarios.csv"; ...
    "stage7_fim_holdout_scenarios.csv"];
method_id = ["FIXED_RECT_3X5";"GREEDY_ETA_080";"FULL_PARENT_5X5"];
subset_id = ["RECT_E14_A31";"RECT_E28_A31";"RECT_E31_A31"];
snr_db = [0, 5, 10];
nmc = 200;
seed_base = 20260719;
status = "POST_HOC_EDGE_SENSITIVITY_NOT_USED_FOR_SELECTION";
version = "STAGE7_1_EDGE_DIAGNOSTIC_PLAN_V1";

rows = cell(numel(scenario_id) * numel(method_id) * numel(snr_db), 1);
row_index = 0;
for scenario_index = 1:numel(scenario_id)
    scenario_table = readtable(fullfile(result_dir, ...
        source_file(scenario_index)), 'TextType', 'string');
    selected = scenario_table( ...
        scenario_table.scenario_id == scenario_id(scenario_index), :);
    if height(selected) ~= 1
        error('build_stage7_1_edge_diagnostic_plan:Scenario', ...
            'Scenario %s must resolve to exactly one frozen row.', ...
            scenario_id(scenario_index));
    end
    scenario = table2struct(selected);
    for method_index = 1:numel(method_id)
        for snr_index = 1:numel(snr_db)
            row_index = row_index + 1;
            row = scenario;
            row.source_scenario_file = source_file(scenario_index);
            row.diagnostic_profile = diagnostic_profile(scenario_index);
            row.method_id = method_id(method_index);
            row.subset_id = subset_id(method_index);
            row.element_snr_db = snr_db(snr_index);
            row.Nmc = nmc;
            row.seed_base = seed_base;
            row.seed = seed_base + 100 * (scenario_index - 1) + ...
                10 * (method_index - 1) + (snr_index - 1);
            row.diagnostic_status = status;
            row.selection_effect_status = ...
                "NOT_USED_FOR_STAGE7_SELECTION_OR_OPERATING_POINT";
            row.plan_version = version;
            rows{row_index} = row;
        end
    end
end
plan = struct2table(vertcat(rows{:}));
if height(plan) ~= 54
    error('build_stage7_1_edge_diagnostic_plan:RowCount', ...
        'The frozen edge plan must contain 54 rows.');
end
plan_hash = stage7_stable_hash(plan, version, seed_base);
end
