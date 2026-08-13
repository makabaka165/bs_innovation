function [G, info] = stage8_k2_tcc_build_g_direct( ...
    target_angles_deg, model, options)
%STAGE8_K2_TCC_BUILD_G_DIRECT Build factor-1 whitened G without derivatives.

if nargin < 3 || isempty(options)
    options = struct();
end
validate_inputs_local(target_angles_deg, model);
angles = double(target_angles_deg);
K = size(angles, 1);
N = numel(model.array_meta.XAct);
A = complex(zeros(N, K));
clock = tic;
for index = 1:K
    a_legacy = build_receive_cyl_steering_vec( ...
        model.array_meta.XAct, model.array_meta.YAct, ...
        model.array_meta.ZAct, angles(index, 1), angles(index, 2), ...
        model.lambda);
    canonical_matrix = reshape_cyl_vector_to_matrix( ...
        a_legacy(:), model.array_meta);
    A(:, index) = canonical_matrix(:);
end
G = model.Tseq * (model.Wseq' * A);
info = struct('target_angles_deg', angles, ...
    'fixed_measurement_hash', char(string(model.fixed_measurement_hash)), ...
    'phase_factor', double(model.phase_factor), ...
    'steering_phase_sign', 1, 'numeric_class', class(G), ...
    'element_steering_actual_order', A, ...
    'num_svd', 0, 'runtime_sec', toc(clock), ...
    'Gseq_size', size(G), 'direct_g_only_flag', true);
if isfield(options, 'compute_rank') && logical(options.compute_rank)
    multiplier = 1;
    if isfield(options, 'rank_multiplier')
        multiplier = options.rank_multiplier;
    end
    [rank_value, singular_values, threshold] = ...
        stage8_k2_tcc_stable_matrix_rank(G, multiplier);
    info.rank_Gseq = rank_value;
    info.singular_values_Gseq = singular_values;
    info.rank_threshold_Gseq = threshold;
    info.num_svd = 1;
else
    info.rank_Gseq = NaN;
    info.singular_values_Gseq = [];
    info.rank_threshold_Gseq = NaN;
end
end

function validate_inputs_local(angles, model)
if ~(isnumeric(angles) && ismatrix(angles) && size(angles, 2) == 2 && ...
        ~isempty(angles) && all(isfinite(angles(:))))
    error('stage8_k2_tcc_build_g_direct:Angles', ...
        'target_angles_deg must be a finite K-by-2 matrix.');
end
required = {'Wseq','Tseq','array_meta','lambda','phase_factor', ...
    'fixed_measurement_hash'};
if ~(isstruct(model) && isscalar(model) && all(isfield(model, required)))
    error('stage8_k2_tcc_build_g_direct:Model', ...
        'model is missing a fixed measurement field.');
end
if double(model.phase_factor) ~= 1
    error('stage8_k2_tcc_build_g_direct:PhaseFactor', ...
        'The Level-A factor-1 contract requires phase_factor=1.');
end
if ~isa(model.Wseq, 'double') || ~isa(model.Tseq, 'double')
    error('stage8_k2_tcc_build_g_direct:NumericClass', ...
        'The Level-A direct path requires double Wseq and Tseq.');
end
if size(model.Wseq, 1) ~= numel(model.array_meta.XAct)
    error('stage8_k2_tcc_build_g_direct:ElementOrder', ...
        'Wseq rows do not match the active element count.');
end
end
