function decision = classify_local_cluster_state( ...
    fit1, fit2, lrt, threshold, separation, diagnostics)
%CLASSIFY_LOCAL_CLUSTER_STATE Apply the frozen six-state Stage8 decision.

if nargin < 6 || isempty(diagnostics)
    diagnostics = struct();
end
forbidden = fieldnames(diagnostics);
for index = 1:numel(forbidden)
    if contains(lower(forbidden{index}), 'truth')
        error('classify_local_cluster_state:HiddenTruth', ...
            'Truth metadata cannot enter the Stage8 state machine.');
    end
end
if ~isfield(diagnostics, 'out_of_local_cell_flag')
    diagnostics.out_of_local_cell_flag = false;
end
[fit1_valid, fit1_validity] = validate_stage8_fit_for_lrt( ...
    fit1, 1, struct());
expected_fit2 = expected_identity_local(fit1);
[fit2_valid, fit2_validity] = validate_stage8_fit_for_lrt( ...
    fit2, 2, expected_fit2);
if diagnostics.out_of_local_cell_flag
    state = 'OUT_OF_LOCAL_CELL';
    reason = 'OBSERVATION_OUTSIDE_REGISTERED_LOCAL_DOMAIN';
elseif strcmp(fit1_validity.status, 'NUMERIC_RANK_DEFICIENT') || ...
        strcmp(fit2_validity.status, 'NUMERIC_RANK_DEFICIENT')
    state = 'NUMERIC_RANK_DEFICIENT';
    reason = 'REQUIRED_MODEL_EFFECTIVE_RANK_DEFICIENT';
elseif ~(fit1_valid && fit2_valid)
    state = 'SEARCH_NOT_CONVERGED';
    reason = 'REQUIRED_K1_OR_K2_FIT_INVALID';
elseif ~strcmp(lrt.lrt_status, 'OK') || ~lrt.nested_rss_pass
    state = 'SEARCH_NOT_CONVERGED';
    reason = 'NESTED_LRT_IMPLEMENTATION_CONTRACT_FAILED';
elseif ~strcmp(threshold.threshold_status, 'LOCKED_BOOTSTRAP_THRESHOLD')
    state = 'SEARCH_NOT_CONVERGED';
    reason = 'LOCKED_THRESHOLD_UNAVAILABLE';
elseif lrt.lambda_12 <= threshold.q_global
    state = 'K1';
    reason = 'GLOBAL_BOOTSTRAP_LRT_NOT_EXCEEDED';
elseif strcmp(separation.confidence_status, 'NUMERIC_RANK_DEFICIENT')
    state = 'NUMERIC_RANK_DEFICIENT';
    reason = 'SEPARATION_BOOTSTRAP_RANK_FAILURE';
elseif ~strcmp(separation.confidence_status, 'OK') || ...
        separation.valid_bootstrap_fraction < separation.minimum_valid_fraction
    state = 'SEARCH_NOT_CONVERGED';
    reason = 'SEPARATION_BOOTSTRAP_VALID_FRACTION_FAILED';
elseif separation.zero_excluded_flag && ...
        separation.engineering_halfwidth_pass
    state = 'K2_RESOLVED';
    reason = 'LRT_AND_SEPARATION_AND_ENGINEERING_GATES_PASSED';
else
    state = 'K2_UNRESOLVED';
    reason = 'K2_EVIDENCE_WITHOUT_RESOLUTION_CONFIDENCE';
end
allowed = {'K1','K2_RESOLVED','K2_UNRESOLVED','OUT_OF_LOCAL_CELL', ...
    'SEARCH_NOT_CONVERGED','NUMERIC_RANK_DEFICIENT'};
if ~ismember(state, allowed)
    error('classify_local_cluster_state:InternalState', ...
        'The classifier produced an unregistered state.');
end
decision = struct('state', state, 'reason', reason, ...
    'estimate_returned_flag', ismember(state, ...
    {'K1','K2_RESOLVED','K2_UNRESOLVED'}), ...
    'model_mismatch_state_status', ...
    'MODEL_MISMATCH_STATE_DISABLED_UNTIL_CALIBRATED_GOF', ...
    'hidden_truth_used_flag', false, ...
    'fit1_validity_status', fit1_validity.status, ...
    'fit2_validity_status', fit2_validity.status, 'phase_factor', 1);
end

function expected = expected_identity_local(fit)
expected = struct();
fields = {'fixed_measurement_hash','local_domain_hash', ...
    'solver_contract_hash','observation_hash'};
for field_index = 1:numel(fields)
    field = fields{field_index};
    if isfield(fit, field)
        expected.(field) = fit.(field);
    end
end
end
