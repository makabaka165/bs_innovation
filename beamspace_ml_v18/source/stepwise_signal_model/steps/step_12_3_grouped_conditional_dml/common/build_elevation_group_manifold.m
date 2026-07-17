function [Ge, dGe, info] = build_elevation_group_manifold(eta_deg, model, opts)
%BUILD_ELEVATION_GROUP_MANIFOLD Build a fixed-whitened elevation manifold.

if nargin < 3 || isempty(opts)
    opts = struct();
end
validate_options_local(opts);
[eta_deg, model] = validate_inputs_local(eta_deg, model);

z_el_m = model.z_el_m(:);
k0 = 2 * pi / model.lambda;
Q = numel(eta_deg);
Az = complex(zeros(numel(z_el_m), Q));
dAz_rad = complex(zeros(numel(z_el_m), Q));
for q = 1:Q
    Az(:, q) = exp(1j * k0 * z_el_m * sind(eta_deg(q)));
    dAz_rad(:, q) = 1j * k0 * z_el_m * cosd(eta_deg(q)) .* Az(:, q);
end

fixed_projection = model.whitener * model.V';
Ge = fixed_projection * Az;
dGe = fixed_projection * dAz_rad;

info = struct();
info.phase_factor = 1;
info.eta_deg = eta_deg;
info.Q = Q;
info.physical_beam_count = size(model.V, 2);
info.whitening_effective_rank = size(model.whitener, 1);
info.output_size = size(Ge);
info.derivative_size = size(dGe);
info.derivative_unit = 'per_radian';
info.fixed_beam_matrix = true;
info.fixed_whitener = true;
info.model_id = model.model_id;
end

function [eta_deg, model] = validate_inputs_local(eta_deg, model)
if ~(isnumeric(eta_deg) && isreal(eta_deg) && isvector(eta_deg) && ...
        ~isempty(eta_deg) && all(isfinite(eta_deg(:))))
    error('build_elevation_group_manifold:Angles', ...
        'eta_deg must be a non-empty finite real vector.');
end
eta_deg = reshape(eta_deg, 1, []);
if ~(isstruct(model) && isscalar(model))
    error('build_elevation_group_manifold:Model', ...
        'model must be a scalar struct.');
end
required = {'V', 'whitener', 'z_el_m', 'lambda', 'phase_factor'};
for idx = 1:numel(required)
    if ~isfield(model, required{idx})
        error('build_elevation_group_manifold:MissingField', ...
            'model.%s is required.', required{idx});
    end
end
if model.phase_factor ~= 1
    error('build_elevation_group_manifold:PhaseFactor', ...
        'The elevation group manifold requires phase_factor=1.');
end
if ~(isnumeric(model.V) && ismatrix(model.V) && ~isempty(model.V) && ...
        all(isfinite(model.V(:))))
    error('build_elevation_group_manifold:BeamMatrix', ...
        'model.V must be a non-empty finite matrix.');
end
if ~(isnumeric(model.whitener) && ismatrix(model.whitener) && ...
        ~isempty(model.whitener) && size(model.whitener, 2) == size(model.V, 2) && ...
        all(isfinite(model.whitener(:))))
    error('build_elevation_group_manifold:Whitener', ...
        'model.whitener must have one column per physical beam.');
end
if ~(isnumeric(model.z_el_m) && isreal(model.z_el_m) && ...
        isvector(model.z_el_m) && numel(model.z_el_m) == size(model.V, 1) && ...
        all(isfinite(model.z_el_m(:))))
    error('build_elevation_group_manifold:ElevationCoordinates', ...
        'model.z_el_m must have one finite real value per elevation element.');
end
if ~(isscalar(model.lambda) && isreal(model.lambda) && ...
        isfinite(model.lambda) && model.lambda > 0)
    error('build_elevation_group_manifold:Wavelength', ...
        'model.lambda must be a positive finite scalar.');
end
if ~isfield(model, 'model_id')
    model.model_id = 'fixed_elevation_beams_and_whitener';
end
if ~(ischar(model.model_id) || ...
        (isstring(model.model_id) && isscalar(model.model_id)))
    error('build_elevation_group_manifold:ModelId', ...
        'model.model_id must be scalar text.');
end
model.model_id = char(model.model_id);
end

function validate_options_local(opts)
if ~(isstruct(opts) && isscalar(opts) && isempty(fieldnames(opts)))
    error('build_elevation_group_manifold:Options', ...
        'No candidate-dependent options are accepted in this fixed model.');
end
end
