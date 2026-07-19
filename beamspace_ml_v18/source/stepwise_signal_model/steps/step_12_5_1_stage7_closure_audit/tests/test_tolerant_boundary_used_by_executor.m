function table_out = test_tolerant_boundary_used_by_executor(result_dir)
%TEST_TOLERANT_BOUNDARY_USED_BY_EXECUTOR Freeze D0286 executor gate.

plan = build_stage7_1_edge_diagnostic_plan(result_dir);
row = plan(plan.scenario_id == "D0286" & ...
    plan.element_snr_db == 0 & plan.method_id == "FIXED_RECT_3X5", :);
opts = struct('unit_test_mode', true, ...
    'raw_trial_factory', @raw_trial_fixture_local);
trial = generate_stage7_1_common_edge_trial(row, 1, struct(), opts);
rejected_row = row;
rejected_row.edge_diagnostic_domain_pass(:) = false;
rejected = throws_local(@() generate_stage7_1_common_edge_trial( ...
    rejected_row, 1, struct(), opts), ...
    'generate_stage7_1_common_edge_trial:DomainGate');

case_id = ["D0286_HISTORICAL_FALSE";"D0286_TOLERANT_TRUE"; ...
    "D0286_EXECUTOR_GENERATES";"D0286_DISAGREEMENT_RETAINED"; ...
    "EXECUTOR_USES_TOLERANT_GATE"];
pass_flag = [~trial.historical_registered_domain_pass; ...
    trial.tolerant_registered_domain_pass; ...
    trial.common_trial_generation_count == 1; ...
    trial.boundary_numeric_disagreement_flag;rejected];
table_out = table(case_id, pass_flag);
assert(all(pass_flag), ...
    'test_tolerant_boundary_used_by_executor:Failed', ...
    'The edge executor did not use the tolerant D0286 boundary gate.');
end

function raw = raw_trial_fixture_local(row, ~, ~, ~)
signal = ones(2, row.L);
noise = 0.1 * ones(2, row.L);
raw = struct('Y_element', signal + noise, 'signal', signal, ...
    'noise', noise, 'source_matrix', ones(2, row.L));
end

function flag = throws_local(action, expected_identifier)
flag = false;
try
    action();
catch exception
    flag = strcmp(exception.identifier, expected_identifier);
end
end
