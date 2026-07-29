function [hybrid_row, selected_source, continuous_upgrade_flag, ...
    fallback_flag] = stage8_core_v2_select_safe_hybrid( ...
    b0_row, continuous_row, hybrid_method_id)
%STAGE8_CORE_V2_SELECT_SAFE_HYBRID Select by validity and log-likelihood.

validate_row_local(b0_row, 'b0_row');
validate_row_local(continuous_row, 'continuous_row');
hybrid_method_id = string(hybrid_method_id);
if ~isscalar(hybrid_method_id) || ...
        ~ismember(hybrid_method_id, ["H1_DIRECT_SAFE_HYBRID_KNOWN_K", ...
        "H2_GROUPED_SAFE_HYBRID_KNOWN_K"])
    error('stage8_core_v2_select_safe_hybrid:Method', ...
        'Hybrid method ID is not registered.');
end

same_identity = b0_row.trial_id == continuous_row.trial_id && ...
    b0_row.element_trial_hash == continuous_row.element_trial_hash && ...
    b0_row.truth_K == continuous_row.truth_K;
if ~same_identity
    error('stage8_core_v2_select_safe_hybrid:ElementIdentity', ...
        'Candidate rows do not describe the same element trial.');
end
if b0_row.method_id ~= "B0_FIXED_GRID_KNOWN_K"
    error('stage8_core_v2_select_safe_hybrid:B0Identity', ...
        'The fallback candidate must be B0_FIXED_GRID_KNOWN_K.');
end
expected_continuous = "B1_DIRECT_CONTINUOUS_KNOWN_K";
if hybrid_method_id == "H2_GROUPED_SAFE_HYBRID_KNOWN_K"
    expected_continuous = "B2_GROUPED_CONTINUOUS_KNOWN_K";
end
if continuous_row.method_id ~= expected_continuous
    error('stage8_core_v2_select_safe_hybrid:ContinuousIdentity', ...
        'Continuous candidate does not match the hybrid method.');
end

leakage = logical(b0_row.truth_used_in_initialization_flag) || ...
    logical(b0_row.truth_used_in_fit_flag) || ...
    logical(continuous_row.truth_used_in_initialization_flag) || ...
    logical(continuous_row.truth_used_in_fit_flag);
if leakage
    error('stage8_core_v2_select_safe_hybrid:TruthLeakage', ...
        'Candidate rows report truth leakage.');
end
if ~logical(b0_row.fit_valid) || ~isfinite(b0_row.loglik)
    error('stage8_core_v2_select_safe_hybrid:InvalidFallback', ...
        'STAGE8_CORE_V2_1_EXPERIMENT_INVALID: B0 fallback is invalid.');
end

continuous_valid = logical(continuous_row.fit_valid);
if continuous_valid && ~isfinite(continuous_row.loglik)
    error('stage8_core_v2_select_safe_hybrid:ContinuousLoglik', ...
        'A valid continuous candidate must have finite log-likelihood.');
end
continuous_upgrade_flag = continuous_valid && ...
    continuous_row.loglik >= b0_row.loglik;
fallback_flag = ~continuous_upgrade_flag;
if continuous_upgrade_flag
    selected = continuous_row;
    selected_source = "CONTINUOUS_UPGRADE";
else
    selected = b0_row;
    selected_source = "FIXED_GRID_FALLBACK";
end

hybrid_row = selected;
hybrid_row.method_id = hybrid_method_id;
hybrid_row.selected_candidate_method_id = selected.method_id;
hybrid_row.continuous_candidate_method_id = continuous_row.method_id;
hybrid_row.selected_source = selected_source;
hybrid_row.continuous_upgrade_flag = logical(continuous_upgrade_flag);
hybrid_row.fallback_flag = logical(fallback_flag);
hybrid_row.selection_truth_used_flag = false;
hybrid_row.selection_rule = ...
    "VALID_CONTINUOUS_WITH_LOG_LIKELIHOOD_NOT_BELOW_B0_ELSE_B0";
hybrid_row.B0_candidate_loglik = double(b0_row.loglik);
hybrid_row.continuous_candidate_loglik = double(continuous_row.loglik);
hybrid_row.B0_candidate_score_calls = double(b0_row.score_calls);
hybrid_row.B0_candidate_SVD_calls = double(b0_row.SVD_calls);
hybrid_row.B0_candidate_runtime_sec = double(b0_row.runtime_sec);
hybrid_row.continuous_candidate_score_calls = ...
    double(continuous_row.score_calls);
hybrid_row.continuous_candidate_SVD_calls = ...
    double(continuous_row.SVD_calls);
hybrid_row.continuous_candidate_runtime_sec = ...
    double(continuous_row.runtime_sec);
hybrid_row.conservative_upper_bound_score_calls = ...
    hybrid_row.B0_candidate_score_calls + ...
    hybrid_row.continuous_candidate_score_calls;
hybrid_row.conservative_upper_bound_SVD_calls = ...
    hybrid_row.B0_candidate_SVD_calls + ...
    hybrid_row.continuous_candidate_SVD_calls;
hybrid_row.conservative_upper_bound_runtime_sec = ...
    hybrid_row.B0_candidate_runtime_sec + ...
    hybrid_row.continuous_candidate_runtime_sec;
hybrid_row.cost_accounting_note = "DOUBLE_COUNTS_SHARED_INITIALIZATION";
end

function validate_row_local(row, argument_name)
required = {'trial_id','element_trial_hash','truth_K','method_id', ...
    'fit_valid','loglik','truth_used_in_initialization_flag', ...
    'truth_used_in_fit_flag','score_calls','SVD_calls','runtime_sec'};
if ~(istable(row) && height(row) == 1) || ...
        ~all(ismember(required, row.Properties.VariableNames))
    error('stage8_core_v2_select_safe_hybrid:Row', ...
        '%s must be one complete table row.', argument_name);
end
end
