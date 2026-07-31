function result = stage8_k2_va_conditional_rho(expansion, R_Z, rho_line_max_deg, constants)
%STAGE8_K2_VA_CONDITIONAL_RHO Apply the frozen conditional AML contract.

if nargin < 4 || isempty(constants)
    constants = stage8_k2_va_constants();
end
validate_inputs_local(expansion, R_Z, rho_line_max_deg, constants);
result = struct('valid', false, 'status', 'CONDITIONAL_RHO_NOT_RUN', ...
    'q0', NaN, 'q1', NaN, 'q2', NaN, 'rho_AML_deg', NaN, ...
    'rho_line_max_deg', double(rho_line_max_deg), ...
    'rho_feasible_max_deg', NaN, 'curvature_valid_flag', false);
if ~expansion.valid
    result.status = 'CONDITIONAL_RHO_PROJECTOR_INVALID';
    return;
end
q0 = real(trace(expansion.P0 * R_Z));
q1 = real(trace(expansion.P1 * R_Z));
q2 = real(trace(expansion.P2 * R_Z));
result.q0 = q0;
result.q1 = q1;
result.q2 = q2;
if any(~isfinite([q0, q1, q2]))
    result.status = 'CONDITIONAL_RHO_NONFINITE_Q';
    return;
end
curvature_threshold = -constants.curvature_epsilon_multiplier * ...
    eps(max(1, abs(q0)));
if ~(q2 < curvature_threshold)
    result.status = 'CONDITIONAL_RHO_NONCONCAVE';
    return;
end
result.curvature_valid_flag = true;
rho = -q1 / (2 * q2);
result.rho_AML_deg = rho;
rho_feasible_max = min(rho_line_max_deg, ...
    constants.rho_close_contract_max_deg);
result.rho_feasible_max_deg = rho_feasible_max;
if ~(isfinite(rho) && isfinite(rho_feasible_max))
    result.status = 'CONDITIONAL_RHO_NONFINITE';
elseif rho < constants.rho_min_deg
    result.status = 'CONDITIONAL_RHO_BELOW_MINIMUM';
elseif rho > rho_line_max_deg
    result.status = 'CONDITIONAL_RHO_ABOVE_LINE_LIMIT';
elseif rho > constants.rho_close_contract_max_deg
    result.status = 'CONDITIONAL_RHO_OUT_OF_CLOSE_CONTRACT';
elseif rho > rho_feasible_max
    result.status = 'CONDITIONAL_RHO_ABOVE_FEASIBLE_LIMIT';
else
    result.valid = true;
    result.status = 'CONDITIONAL_RHO_VALID';
end
end

function validate_inputs_local(expansion, R_Z, rho_line_max_deg, constants)
if ~(isstruct(expansion) && isfield(expansion, 'valid') && ...
        isfield(expansion, 'P0') && isfield(expansion, 'P1') && ...
        isfield(expansion, 'P2') && isnumeric(R_Z) && ismatrix(R_Z) && ...
        size(R_Z, 1) == size(R_Z, 2) && all(isfinite(R_Z(:))) && ...
        isscalar(rho_line_max_deg) && isfinite(rho_line_max_deg) && ...
        isstruct(constants) && isfield(constants, 'rho_min_deg') && ...
        isfield(constants, 'rho_close_contract_max_deg'))
    error('stage8_k2_va_conditional_rho:Input', ...
        'The projector, data energy matrix, or close-pair contract is invalid.');
end
end
