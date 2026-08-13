function [Y_white, info] = stage8_k2_cb_whiten_element_data(Y_element, model)
%STAGE8_K2_CB_WHITEN_ELEMENT_DATA Apply exact element covariance whitening.

if ~(isnumeric(Y_element) && ismatrix(Y_element) && ...
        size(Y_element, 1) == size(model.Rn_elem, 1) && ...
        all(isfinite(Y_element(:))))
    error('stage8_k2_cb_whiten_element_data:Data', ...
        'Element data must be finite and match model.Rn_elem.');
end
R = 0.5 * (model.Rn_elem + model.Rn_elem');
identity = eye(size(R), 'like', R);
[factor, failure] = chol(R, 'lower');
eig_calls = 0;
if failure == 0
    whitener = factor \ identity;
    method = 'CHOLESKY_LOWER';
    numeric_rank = size(R, 1);
else
    [vectors, values] = eig(R, 'vector');
    eig_calls = 1;
    values = real(values);
    threshold = size(R, 1) * eps(max(1, max(abs(values))));
    numeric_rank = nnz(values > threshold);
    if numeric_rank ~= size(R, 1)
        error('stage8_k2_cb_whiten_element_data:CovarianceRank', ...
            'model.Rn_elem is not positive definite at numeric precision.');
    end
    whitener = diag(1 ./ sqrt(values)) * vectors';
    method = 'HERMITIAN_EIG';
end
whitening_error = norm(whitener * R * whitener' - identity, 'fro') / ...
    max(1, norm(identity, 'fro'));
if ~(isfinite(whitening_error) && whitening_error <= 1e-8)
    error('stage8_k2_cb_whiten_element_data:WhiteningError', ...
        'Element covariance whitening failed its identity contract.');
end
Y_white = whitener * Y_element;
info = struct('whitener', whitener, 'method', method, ...
    'whitening_error', whitening_error, 'numeric_rank', numeric_rank, ...
    'eig_call_count', eig_calls, 'chol_call_count', 1, ...
    'noise_profile_id', string(model.noise_profile_id));
end
