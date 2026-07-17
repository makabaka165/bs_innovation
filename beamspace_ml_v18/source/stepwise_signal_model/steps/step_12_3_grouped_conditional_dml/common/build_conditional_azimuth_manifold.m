function [Gphi, dGphi, info] = build_conditional_azimuth_manifold( ...
    az_candidate_deg, model, opts)
%BUILD_CONDITIONAL_AZIMUTH_MANIFOLD Build fixed-whitener conditional columns.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
az_candidate_deg = az_candidate_deg(:).';
if isempty(az_candidate_deg) || numel(az_candidate_deg) > 2 || ...
        ~isreal(az_candidate_deg) || any(~isfinite(az_candidate_deg))
    error('build_conditional_azimuth_manifold:Candidates', ...
        'az_candidate_deg must contain one or two finite real angles.');
end
validate_model_local(model);

x = model.array_coordinates(:, 1);
y = model.array_coordinates(:, 2);
k0 = 2 * pi / model.lambda;
el_rad = deg2rad(model.eta_condition_deg);
Kq = numel(az_candidate_deg);
Aphi = complex(zeros(numel(x), Kq));
dAphi = complex(zeros(numel(x), Kq));
for idx = 1:Kq
    az_rad = deg2rad(az_candidate_deg(idx));
    phase = k0 * cos(el_rad) * ...
        (x * cos(az_rad) + y * sin(az_rad));
    phase_derivative = k0 * cos(el_rad) * ...
        (-x * sin(az_rad) + y * cos(az_rad));
    Aphi(:, idx) = exp(1j * phase);
    dAphi(:, idx) = 1j * phase_derivative .* Aphi(:, idx);
end
Gphi = model.Tphi_q * (model.Uq' * Aphi);
dGphi = model.Tphi_q * (model.Uq' * dAphi);
[rank_Gphi, singular_values, threshold] = ...
    stable_matrix_rank(Gphi, opts.rank_multiplier);

info = struct();
info.rank_Gphi = rank_Gphi;
info.singular_values_Gphi = singular_values;
info.rank_threshold_Gphi = threshold;
info.az_candidate_deg = az_candidate_deg;
info.eta_condition_deg = model.eta_condition_deg;
info.derivative_coordinate = 'radian';
info.cos_elevation_dependence_flag = true;
info.fixed_measurement_hash = model.fixed_measurement_hash;
info.beam_bank_hash = model.beam_bank_hash;
info.candidate_independent_measurement_flag = true;
info.phase_factor = 1;
info.num_svd = 1;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_conditional_azimuth_manifold:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_conditional_azimuth_manifold:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
end

function validate_model_local(model)
required = {'Uq','Tphi_q','array_coordinates','lambda', ...
    'eta_condition_deg','phase_factor','fixed_measurement_hash','beam_bank_hash'};
if ~(isstruct(model) && isscalar(model) && all(isfield(model, required)))
    error('build_conditional_azimuth_manifold:Model', ...
        'model is missing a fixed conditional-measurement field.');
end
if model.phase_factor ~= 1
    error('build_conditional_azimuth_manifold:PhaseFactor', ...
        'The active conditional manifold requires phase_factor=1.');
end
if size(model.array_coordinates, 2) < 2 || ...
        size(model.array_coordinates, 1) ~= size(model.Uq, 1) || ...
        size(model.Tphi_q, 2) ~= size(model.Uq, 2)
    error('build_conditional_azimuth_manifold:Dimensions', ...
        'The fixed Uq, Tphi_q, and coordinate dimensions are inconsistent.');
end
end
