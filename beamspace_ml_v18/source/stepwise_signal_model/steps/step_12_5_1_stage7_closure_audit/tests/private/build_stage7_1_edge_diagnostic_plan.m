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
common_trial_status = ...
    "GENERATE_ELEMENT_DOMAIN_TRIAL_ONCE_THEN_APPLY_THREE_PHYSICAL_SUBSETS";
domain_bounds_deg = [7.4,8.6;9.6,10.4];
version = "STAGE7_1_EDGE_DIAGNOSTIC_PLAN_V2_PAIRED_TOLERANT_DOMAIN";

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
    targets_deg = [scenario.target1_az_deg,scenario.target1_el_deg; ...
        scenario.target2_az_deg,scenario.target2_el_deg];
    domain = evaluate_stage7_1_tolerant_domain_check( ...
        targets_deg, domain_bounds_deg, scenario.registered_domain_pass);
    for snr_index = 1:numel(snr_db)
        paired_group_id = sprintf('EDGE_%s_SNR_%+03d_DB', ...
            scenario_id(scenario_index), snr_db(snr_index));
        paired_seed = seed_base + 100 * (scenario_index - 1) + ...
            (snr_index - 1);
        for method_index = 1:numel(method_id)
            row_index = row_index + 1;
            row = scenario;
            row.source_scenario_file = source_file(scenario_index);
            row.diagnostic_profile = diagnostic_profile(scenario_index);
            row.method_id = method_id(method_index);
            row.subset_id = subset_id(method_index);
            row.element_snr_db = snr_db(snr_index);
            row.Nmc = nmc;
            row.seed_base = seed_base;
            row.seed = paired_seed;
            row.paired_group_id = paired_group_id;
            row.common_trial_generation_status = common_trial_status;
            row.historical_registered_domain_pass = ...
                domain.historical_registered_domain_pass;
            row.tolerant_registered_domain_pass = ...
                domain.tolerant_registered_domain_pass;
            row.boundary_numeric_disagreement_flag = ...
                domain.boundary_numeric_disagreement_flag;
            row.domain_tolerance_deg = domain.domain_tolerance_deg;
            row.domain_scale_deg = domain.domain_scale_deg;
            row.domain_parameter_dimension = ...
                domain.domain_parameter_dimension;
            row.edge_diagnostic_domain_pass = ...
                domain.edge_diagnostic_domain_pass;
            row.domain_tolerance_formula = domain.domain_tolerance_formula;
            row.domain_gate_source = domain.domain_gate_source;
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
