function [noise_model, debug] = propagate_group_recovery_noise( ...
    Ge_hat, Rphi_selected, opts)
%PROPAGATE_GROUP_RECOVERY_NOISE Propagate row-whitened recovery noise.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_inputs_local(Ge_hat, Rphi_selected);
Q = size(Ge_hat, 2);
B = size(Ge_hat, 1);

[H_e, solve_info] = stable_svd_solve( ...
    Ge_hat, eye(B, 'like', Ge_hat), Q, opts.rank_multiplier);
R_group = H_e * H_e';
R_group = 0.5 * (R_group + R_group');
group_noise_scale = real(diag(R_group));
denominator = sqrt(max(group_noise_scale, 0) * ...
    max(group_noise_scale, 0).');
cross_group_noise_correlation = complex(NaN(Q, Q));
valid = denominator > 0;
cross_group_noise_correlation(valid) = R_group(valid) ./ denominator(valid);

if solve_info.effective_rank < Q
    status = 'GROUP_NOISE_PROPAGATION_RANK_UNCERTIFIED';
else
    status = 'GROUP_NOISE_PROPAGATION_RETURNED';
end

noise_model = struct();
noise_model.R_group = R_group;
noise_model.group_noise_scale = group_noise_scale;
noise_model.cross_group_noise_correlation = cross_group_noise_correlation;
noise_model.Rphi_selected = Rphi_selected;
noise_model.rank_Ge = solve_info.effective_rank;
noise_model.phase_factor = 1;
noise_model.num_svd = solve_info.num_svd;
noise_model.status = status;
noise_model.statistical_calibration_status = 'NOT_CALIBRATED_STAGE5';

debug = solve_info;
debug.H_e = H_e;
debug.gram_inverse_used_flag = false;
debug.full_cross_group_covariance_retained_flag = true;
debug.phase_factor = 1;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('propagate_group_recovery_noise:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier', 'phase_factor'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('propagate_group_recovery_noise:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'phase_factor')
    opts.phase_factor = 1;
end
if opts.phase_factor ~= 1
    error('propagate_group_recovery_noise:PhaseFactor', ...
        'The active recovery-noise model requires phase_factor=1.');
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('propagate_group_recovery_noise:RankMultiplier', ...
        'rank_multiplier must be positive and finite.');
end
end

function validate_inputs_local(G, R)
if ~(isnumeric(G) && ismatrix(G) && ~isempty(G) && ...
        all(isfinite(G(:))) && size(G, 1) >= size(G, 2))
    error('propagate_group_recovery_noise:Manifold', ...
        'Ge_hat must be a finite non-empty matrix with rows >= columns.');
end
if ~(isnumeric(R) && ismatrix(R) && ~isempty(R) && ...
        size(R, 1) == size(R, 2) && all(isfinite(R(:))))
    error('propagate_group_recovery_noise:Covariance', ...
        'Rphi_selected must be a finite non-empty square matrix.');
end
end
