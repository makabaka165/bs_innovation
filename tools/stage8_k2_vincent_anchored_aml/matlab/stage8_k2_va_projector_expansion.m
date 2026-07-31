function expansion = stage8_k2_va_projector_expansion(derivatives, rank_multiplier)
%STAGE8_K2_VA_PROJECTOR_EXPANSION Build the Hermitian O(rho^2) projector.

if nargin < 2 || isempty(rank_multiplier)
    rank_multiplier = stage8_k2_va_constants().rank_multiplier;
end
validate_inputs_local(derivatives, rank_multiplier);
h0 = derivatives.h0;
h1 = derivatives.h1;
h2 = derivatives.h2;
h3 = derivatives.h3;
B0 = [h0, h1];
B1 = [zeros(size(h0), 'like', h0), h2 / 2];
B2 = [zeros(size(h0), 'like', h0), h3 / 3];
[U, S, V] = svd(B0, 'econ');
singular_values = real(diag(S));
[B0_rank, rank_threshold] = stable_numeric_rank( ...
    singular_values, size(B0), rank_multiplier);
condition = Inf;
if B0_rank == 2
    condition = singular_values(1) / singular_values(2);
end
expansion = template_local(B0_rank, rank_threshold, singular_values, ...
    condition, B0, B1, B2);
if B0_rank ~= 2
    expansion.status = 'PROJECTOR_B0_RANK_DEFICIENT';
    return;
end

right_transform = V * diag(1 ./ singular_values);
C0 = B0 * right_transform;
C1 = B1 * right_transform;
C2 = B2 * right_transform;
H0 = C0' * C0;
H1 = C1' * C0 + C0' * C1;
H2 = C2' * C0 + 2 * C1' * C1 + C0' * C2;
K0 = H0 \ eye(2, 'like', H0);
K1 = -K0 * H1 * K0;
K2 = 2 * K0 * H1 * K0 * H1 * K0 - K0 * H2 * K0;
P0 = C0 * K0 * C0';
P1 = C1 * K0 * C0' + C0 * K1 * C0' + C0 * K0 * C1';
P2 = 0.5 * ( ...
    C2 * K0 * C0' + 2 * C1 * K1 * C0' + ...
    2 * (C1 * K0 * C1') + C0 * K2 * C0' + ...
    2 * C0 * K1 * C1' + C0 * K0 * C2');
P0 = 0.5 * (P0 + P0');
P1 = 0.5 * (P1 + P1');
P2 = 0.5 * (P2 + P2');
if any(~isfinite([P0(:); P1(:); P2(:)]))
    expansion.status = 'PROJECTOR_EXPANSION_NONFINITE';
    return;
end
expansion.valid = true;
expansion.status = 'PROJECTOR_EXPANSION_VALID';
expansion.P0 = P0;
expansion.P1 = P1;
expansion.P2 = P2;
expansion.C0 = C0;
expansion.C1 = C1;
expansion.C2 = C2;
expansion.K0 = K0;
expansion.K1 = K1;
expansion.K2 = K2;
expansion.idempotence_error = norm(P0 * P0 - P0, 'fro') / ...
    max(1, norm(P0, 'fro'));
expansion.C0_orthonormality_error = norm(C0' * C0 - eye(2), 'fro');
expansion.U_reconstruction_error = norm(C0 - U, 'fro') / ...
    max(1, norm(U, 'fro'));
end

function expansion = template_local(rank_value, threshold, singular_values, ...
    condition, B0, B1, B2)
dimension = size(B0, 1);
zero_matrix = complex(zeros(dimension, dimension));
expansion = struct('valid', false, 'status', 'NOT_RUN', ...
    'B0_rank', double(rank_value), ...
    'B0_rank_threshold', double(threshold), ...
    'B0_singular_values', singular_values(:).', ...
    'B0_condition', double(condition), 'B0', B0, 'B1', B1, 'B2', B2, ...
    'C0', complex(zeros(dimension, 2)), ...
    'C1', complex(zeros(dimension, 2)), ...
    'C2', complex(zeros(dimension, 2)), ...
    'K0', complex(zeros(2)), 'K1', complex(zeros(2)), ...
    'K2', complex(zeros(2)), 'P0', zero_matrix, 'P1', zero_matrix, ...
    'P2', zero_matrix, 'idempotence_error', NaN, ...
    'C0_orthonormality_error', NaN, 'U_reconstruction_error', NaN, ...
    'num_svd', 1);
end

function validate_inputs_local(derivatives, rank_multiplier)
required = {'h0','h1','h2','h3'};
if ~(isstruct(derivatives) && all(isfield(derivatives, required)) && ...
        isscalar(rank_multiplier) && isfinite(rank_multiplier) && ...
        rank_multiplier > 0)
    error('stage8_k2_va_projector_expansion:Input', ...
        'Directional derivatives or rank multiplier are invalid.');
end
for index = 1:numel(required)
    value = derivatives.(required{index});
    if ~(isnumeric(value) && isvector(value) && ~isempty(value) && ...
            all(isfinite(value(:))))
        error('stage8_k2_va_projector_expansion:Derivative', ...
            'Each directional derivative must be a finite complex vector.');
    end
end
end
