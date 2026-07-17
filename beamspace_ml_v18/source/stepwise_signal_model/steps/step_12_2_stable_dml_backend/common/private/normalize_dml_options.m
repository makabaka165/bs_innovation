function opts = normalize_dml_options(opts, K, caller_name)
%NORMALIZE_DML_OPTIONS Normalize options shared by stable score modules.

if nargin < 1 || isempty(opts)
    opts = struct();
end
if ~(isstruct(opts) && isscalar(opts))
    error([caller_name ':Options'], 'opts must be a scalar struct.');
end
allowed = {'rank_multiplier', 'requested_rank', ...
    'rss_tolerance_multiplier', 'compute_projector_checks'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error([caller_name ':UnknownOption'], ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'requested_rank')
    opts.requested_rank = K;
end
if ~isfield(opts, 'rss_tolerance_multiplier')
    opts.rss_tolerance_multiplier = 10;
end
if ~isfield(opts, 'compute_projector_checks')
    opts.compute_projector_checks = false;
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error([caller_name ':RankMultiplier'], ...
        'opts.rank_multiplier must be a positive finite scalar.');
end
if ~(isscalar(opts.requested_rank) && isfinite(opts.requested_rank) && ...
        opts.requested_rank >= 1 && opts.requested_rank <= K && ...
        opts.requested_rank == fix(opts.requested_rank))
    error([caller_name ':RequestedRank'], ...
        'opts.requested_rank must be an integer from 1 through size(G,2).');
end
if ~(isscalar(opts.rss_tolerance_multiplier) && ...
        isfinite(opts.rss_tolerance_multiplier) && ...
        opts.rss_tolerance_multiplier > 0)
    error([caller_name ':RSSToleranceMultiplier'], ...
        'opts.rss_tolerance_multiplier must be a positive finite scalar.');
end
if ~(islogical(opts.compute_projector_checks) && ...
        isscalar(opts.compute_projector_checks))
    error([caller_name ':ProjectorChecks'], ...
        'opts.compute_projector_checks must be a logical scalar.');
end
end
