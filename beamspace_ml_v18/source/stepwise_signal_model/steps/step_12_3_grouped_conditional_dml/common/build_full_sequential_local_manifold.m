function [Gseq, dGseq, info] = build_full_sequential_local_manifold( ...
    target_angles_deg, model, opts)
%BUILD_FULL_SEQUENTIAL_LOCAL_MANIFOLD Project the full factor-1 receive model.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_inputs_local(target_angles_deg, model);
K = size(target_angles_deg, 1);
B = size(model.Wseq, 2);
A = complex(zeros(size(model.Wseq, 1), K));
dA_az = complex(zeros(size(A)));
dA_el = complex(zeros(size(A)));

for idx = 1:K
    az_deg = target_angles_deg(idx, 1);
    el_deg = target_angles_deg(idx, 2);
    a_legacy = build_receive_cyl_steering_vec( ...
        model.array_meta.XAct, model.array_meta.YAct, model.array_meta.ZAct, ...
        az_deg, el_deg, model.lambda);
    az_rad = deg2rad(az_deg);
    el_rad = deg2rad(el_deg);
    x = model.array_meta.XAct(:);
    y = model.array_meta.YAct(:);
    z = model.array_meta.ZAct(:);
    k0 = 2 * pi / model.lambda;
    dphase_az = k0 * cos(el_rad) * ...
        (-x * sin(az_rad) + y * cos(az_rad));
    dphase_el = k0 * (-sin(el_rad) * ...
        (x * cos(az_rad) + y * sin(az_rad)) + z * cos(el_rad));
    da_az_legacy = 1j * dphase_az .* a_legacy;
    da_el_legacy = 1j * dphase_el .* a_legacy;
    A(:, idx) = canonicalize_local(a_legacy, model.array_meta);
    dA_az(:, idx) = canonicalize_local(da_az_legacy, model.array_meta);
    dA_el(:, idx) = canonicalize_local(da_el_legacy, model.array_meta);
end

Gseq = model.Tseq * (model.Wseq' * A);
dGseq = struct('azimuth', model.Tseq * (model.Wseq' * dA_az), ...
    'elevation', model.Tseq * (model.Wseq' * dA_el), ...
    'coordinate', 'radian');
[rank_Gseq, singular_values, threshold] = ...
    stable_matrix_rank(Gseq, opts.rank_multiplier);

info = struct();
info.rank_Gseq = rank_Gseq;
info.singular_values_Gseq = singular_values;
info.rank_threshold_Gseq = threshold;
info.target_angles_deg = target_angles_deg;
info.full_receive_geometry_used_flag = true;
info.factorized_scoring_used_flag = false;
info.fixed_measurement_hash = model.fixed_measurement_hash;
info.phase_factor = 1;
info.num_svd = 1;
info.Gseq_size = [B, K];
end

function vector = canonicalize_local(legacy_vector, array_meta)
matrix = reshape_cyl_vector_to_matrix(legacy_vector, array_meta);
vector = matrix(:);
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_full_sequential_local_manifold:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_full_sequential_local_manifold:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
end

function validate_inputs_local(angles, model)
if ~(isnumeric(angles) && ismatrix(angles) && size(angles, 2) == 2 && ...
        ~isempty(angles) && all(isfinite(angles(:))))
    error('build_full_sequential_local_manifold:Angles', ...
        'target_angles_deg must be a finite K-by-2 [azimuth,elevation] matrix.');
end
required = {'Wseq','Tseq','array_meta','lambda','phase_factor', ...
    'fixed_measurement_hash'};
if ~(isstruct(model) && isscalar(model) && all(isfield(model, required)))
    error('build_full_sequential_local_manifold:Model', ...
        'model is missing a fixed full-sequential field.');
end
if model.phase_factor ~= 1
    error('build_full_sequential_local_manifold:PhaseFactor', ...
        'The active full sequential manifold requires phase_factor=1.');
end
end
