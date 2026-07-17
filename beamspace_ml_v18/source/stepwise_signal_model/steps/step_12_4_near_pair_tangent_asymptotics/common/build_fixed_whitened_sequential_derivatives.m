function [g, Jg, info] = build_fixed_whitened_sequential_derivatives( ...
    center_deg, model, opts)
%BUILD_FIXED_WHITENED_SEQUENTIAL_DERIVATIVES Project factor-1 derivatives.

if nargin < 3
    opts = struct();
end
validate_inputs_local(center_deg, model, opts);
[a_legacy, da_az_legacy, da_el_legacy, receive_meta] = ...
    build_receive_cyl_steering_with_derivatives( ...
    model.array_meta.XAct, model.array_meta.YAct, model.array_meta.ZAct, ...
    center_deg(1), center_deg(2), model.lambda);
a = canonicalize_local(a_legacy, model.array_meta);
da_az = canonicalize_local(da_az_legacy, model.array_meta);
da_el = canonicalize_local(da_el_legacy, model.array_meta);
projection = model.Tseq * model.Wseq';
g = projection * a;
Jg = projection * [da_az, da_el];

info = struct();
info.derivative_unit = 'per_radian';
info.input_angle_unit = 'degree';
info.fixed_measurement_hash = model.fixed_measurement_hash;
info.phase_factor = receive_meta.phase_factor;
info.g_norm = norm(g);
info.Jg_norm = norm(Jg, 'fro');
info.whitening_rank = model.whitening_rank;
info.center_deg = reshape(center_deg, 1, 2);
info.num_receive_manifold_evaluations = 1;
end

function vector = canonicalize_local(legacy_vector, array_meta)
matrix = reshape_cyl_vector_to_matrix(legacy_vector, array_meta);
vector = matrix(:);
end

function validate_inputs_local(center_deg, model, opts)
if ~(isnumeric(center_deg) && isreal(center_deg) && ...
        isequal(size(center_deg), [1, 2]) && all(isfinite(center_deg)))
    error('build_fixed_whitened_sequential_derivatives:Center', ...
        'center_deg must be one finite [azimuth,elevation] row.');
end
required = {'Wseq','Tseq','array_meta','lambda','phase_factor', ...
    'fixed_measurement_hash','whitening_rank'};
if ~(isstruct(model) && isscalar(model) && all(isfield(model, required)))
    error('build_fixed_whitened_sequential_derivatives:Model', ...
        'model is missing a fixed measurement field.');
end
if model.phase_factor ~= 1
    error('build_fixed_whitened_sequential_derivatives:PhaseFactor', ...
        'The active stage-6 manifold requires phase_factor=1.');
end
if ~(isstruct(opts) && isscalar(opts) && isempty(fieldnames(opts)))
    error('build_fixed_whitened_sequential_derivatives:Options', ...
        'No angle-dependent measurement options are accepted.');
end
end
