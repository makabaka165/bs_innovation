function [T_row, T_col, info] = build_separable_mmv_whiteners( ...
    C_row, C_col, opts)
%BUILD_SEPARABLE_MMV_WHITENERS Build fixed matrix-normal row/column whiteners.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
whitener_opts = struct( ...
    'rank_multiplier', opts.rank_multiplier, ...
    'psd_tolerance_multiplier', opts.psd_tolerance_multiplier);

[T_row, row_info] = build_psd_whitener(C_row, whitener_opts);
[T_col, column_info] = build_psd_whitener(C_col, whitener_opts);

info = struct();
info.row_rank = row_info.rank;
info.column_rank = column_info.rank;
info.row_whitening_error = row_info.whitening_error;
info.column_whitening_error = column_info.whitening_error;
info.row_eigenvalues = row_info.eigenvalues;
info.column_eigenvalues = column_info.eigenvalues;
info.row_info = row_info;
info.column_info = column_info;
info.phase_factor = 1;
info.model = 'matrix_normal_separable';
info.num_eigendecompositions = 2;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_separable_mmv_whiteners:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier', 'psd_tolerance_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_separable_mmv_whiteners:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'psd_tolerance_multiplier')
    opts.psd_tolerance_multiplier = opts.rank_multiplier;
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('build_separable_mmv_whiteners:RankMultiplier', ...
        'opts.rank_multiplier must be positive and finite.');
end
if ~(isscalar(opts.psd_tolerance_multiplier) && ...
        isfinite(opts.psd_tolerance_multiplier) && ...
        opts.psd_tolerance_multiplier > 0)
    error('build_separable_mmv_whiteners:PSDToleranceMultiplier', ...
        'opts.psd_tolerance_multiplier must be positive and finite.');
end
end
