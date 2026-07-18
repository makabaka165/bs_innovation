function model = build_exact_subset_model(pool, channels, noise, opts)
%BUILD_EXACT_SUBSET_MODEL Reconstruct covariance and whitener for one subset.

if nargin < 4 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'rank_multiplier'), opts.rank_multiplier = 1; end
if ~isfield(opts, 'compute_hash'), opts.compute_hash = false; end
channels = channels(:).';
if isempty(channels) || any(channels < 1) || ...
        any(channels > size(pool.W0, 2)) || ...
        any(channels ~= fix(channels)) || numel(unique(channels)) ~= numel(channels)
    error('build_exact_subset_model:Channels', ...
        'channels must be unique valid parent-pool column indices.');
end
W_I = pool.W0(:, channels);
if isfield(noise, 'C0')
    C0 = noise.C0;
    C_I = C0(channels, channels);
else
    C_I = W_I' * noise.Rn * W_I;
    C0 = pool.W0' * noise.Rn * pool.W0;
end
C_I = 0.5 * (C_I + C_I');
[T_I, whitening_info] = build_psd_whitener(C_I, struct( ...
    'rank_multiplier', opts.rank_multiplier, ...
    'psd_tolerance_multiplier', opts.rank_multiplier));
C_from_selection = C0(channels, channels);
covariance_selection_error = norm(C_I - C_from_selection, 'fro') / ...
    max(norm(C_I, 'fro'), realmin);
if opts.compute_hash
    subset_model_hash = stage7_stable_hash(channels, C_I, T_I, noise.hash);
else
    subset_model_hash = '';
end
model = struct('channels', channels, 'W_I', W_I, 'C_I', C_I, ...
    'T_I', T_I, 'rank_C_I', whitening_info.rank, ...
    'whitening_info', whitening_info, ...
    'covariance_selection_error', covariance_selection_error, ...
    'noise_id', noise.noise_id, 'subset_model_hash', subset_model_hash);
end
