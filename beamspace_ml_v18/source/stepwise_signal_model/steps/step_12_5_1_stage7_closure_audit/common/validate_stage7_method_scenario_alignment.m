function contract = validate_stage7_method_scenario_alignment( ...
    summary, method_ids)
%VALIDATE_STAGE7_METHOD_SCENARIO_ALIGNMENT Enforce paired-summary alignment.

required = {'method_id','scenario_id','n_trials'};
if ~(istable(summary) && ...
        all(ismember(required, summary.Properties.VariableNames)))
    error('validate_stage7_method_scenario_alignment:Schema', ...
        'summary must contain method_id, scenario_id, and n_trials.');
end
method_ids = string(method_ids(:));
if isempty(method_ids) || any(ismissing(method_ids) | strlength(method_ids) == 0) || ...
        numel(unique(method_ids)) ~= numel(method_ids)
    error('validate_stage7_method_scenario_alignment:Methods', ...
        'method_ids must contain unique nonmissing labels.');
end
if any(~isfinite(summary.n_trials) | summary.n_trials <= 0 | ...
        summary.n_trials ~= fix(summary.n_trials))
    error('validate_stage7_method_scenario_alignment:TrialValue', ...
        'All n_trials values must be positive integers.');
end

reference_rows = summary(summary.method_id == method_ids(1), :);
if isempty(reference_rows)
    error('validate_stage7_method_scenario_alignment:MissingMethod', ...
        'Missing comparison method %s.', method_ids(1));
end
reference_scenarios = sort(unique(reference_rows.scenario_id));
for method_index = 1:numel(method_ids)
    selected = summary(summary.method_id == method_ids(method_index), :);
    if isempty(selected)
        error('validate_stage7_method_scenario_alignment:MissingMethod', ...
            'Missing comparison method %s.', method_ids(method_index));
    end
    [unique_scenarios, ~, group_index] = unique(selected.scenario_id);
    counts = accumarray(group_index, 1);
    if any(counts ~= 1)
        error('validate_stage7_method_scenario_alignment:DuplicateScenario', ...
            'Method %s has duplicate scenario rows.', method_ids(method_index));
    end
    if ~isequal(sort(unique_scenarios), reference_scenarios)
        error('validate_stage7_method_scenario_alignment:ScenarioSet', ...
            'All comparison methods must share the same scenario_id set.');
    end
end

for scenario_index = 1:numel(reference_scenarios)
    selected = summary(summary.scenario_id == reference_scenarios(scenario_index) & ...
        ismember(summary.method_id, method_ids), :);
    if height(selected) ~= numel(method_ids) || ...
            numel(unique(selected.method_id)) ~= numel(method_ids)
        error('validate_stage7_method_scenario_alignment:ScenarioRows', ...
            'Scenario %s does not contain exactly one row per method.', ...
            reference_scenarios(scenario_index));
    end
    if numel(unique(selected.n_trials)) ~= 1
        error('validate_stage7_method_scenario_alignment:TrialCount', ...
            'Scenario %s has inconsistent n_trials across methods.', ...
            reference_scenarios(scenario_index));
    end
end

contract = struct();
contract.method_count = numel(method_ids);
contract.scenario_count = numel(reference_scenarios);
contract.method_ids = method_ids;
contract.scenario_ids = reference_scenarios;
contract.alignment_status = ...
    'PASS_IDENTICAL_SCENARIO_SET_AND_PER_SCENARIO_TRIAL_COUNT';
end
