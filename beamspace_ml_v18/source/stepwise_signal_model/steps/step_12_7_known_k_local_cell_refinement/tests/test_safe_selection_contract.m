function test_safe_selection_contract()
%TEST_SAFE_SELECTION_CONTRACT Confirm validity-plus-loglik safe selection.

b0 = candidate_local(true, -10, 'B0_FIXED_GRID_KNOWN_K');
continuous = candidate_local(true, -9, 'B1_DIRECT_CONTINUOUS_KNOWN_K');
[selected, audit] = select_stage8_safe_known_k_candidate(b0, continuous);
assert(strcmp(selected.method_id, 'B1_DIRECT_CONTINUOUS_KNOWN_K'));
assert(audit.continuous_upgrade_flag && ~audit.fallback_flag);
continuous = candidate_local(false, -8, 'B1_DIRECT_CONTINUOUS_KNOWN_K');
[selected, audit] = select_stage8_safe_known_k_candidate(b0, continuous);
assert(strcmp(selected.method_id, 'B0_FIXED_GRID_KNOWN_K'));
assert(~audit.continuous_upgrade_flag && audit.fallback_flag);
end

function candidate = candidate_local(valid, loglik, method_id)
fit = struct('loglik_concentrated', loglik);
candidate = struct('fit', fit, 'fit_valid', valid, ...
    'fit_status', 'KNOWN_K_FIT_VALID', 'method_id', method_id);
end
