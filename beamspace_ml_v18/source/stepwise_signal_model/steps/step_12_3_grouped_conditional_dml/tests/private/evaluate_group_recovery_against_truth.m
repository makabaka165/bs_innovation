function metrics = evaluate_group_recovery_against_truth( ...
    Xphi_hat, Ce_hat, Ge_hat, truth, opts)
%EVALUATE_GROUP_RECOVERY_AGAINST_TRUTH Test-only recovery error metrics.

if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_inputs_local(Xphi_hat, Ce_hat, Ge_hat, truth);
Q = numel(Xphi_hat);

relative_fro_error_by_group = NaN(Q, 1);
subspace_chordal_distance_by_group = NaN(Q, 1);
subspace_rank_estimate = NaN(Q, 1);
subspace_rank_truth = NaN(Q, 1);
num_svd = 0;
for q = 1:Q
    X_true = truth.Xphi{q};
    relative_fro_error_by_group(q) = ...
        norm(Xphi_hat{q} - X_true, 'fro') / ...
        max(norm(X_true, 'fro'), realmin(class(X_true)));
    [subspace_chordal_distance_by_group(q), subspace_info] = ...
        subspace_distance_local(Xphi_hat{q}(:), X_true(:), ...
        opts.rank_multiplier);
    subspace_rank_estimate(q) = subspace_info.rank_a;
    subspace_rank_truth(q) = subspace_info.rank_b;
    num_svd = num_svd + subspace_info.num_svd;
end

[mixing, mixing_info] = stable_svd_solve_local( ...
    Ge_hat, truth.Ge, Q, opts.rank_multiplier);
crosstalk_matrix = abs(mixing);
off_diagonal = crosstalk_matrix;
off_diagonal(1:(Q + 1):end) = 0;

metrics = struct();
metrics.evaluation_scope = 'TEST_ONLY_TRUTH_EVALUATOR';
metrics.relative_fro_error_by_group = relative_fro_error_by_group;
metrics.overall_relative_fro_error = ...
    norm(Ce_hat - truth.Ce_recovery, 'fro') / ...
    max(norm(truth.Ce_recovery, 'fro'), ...
    realmin(class(truth.Ce_recovery)));
metrics.subspace_chordal_distance_by_group = ...
    subspace_chordal_distance_by_group;
metrics.subspace_rank_estimate = subspace_rank_estimate;
metrics.subspace_rank_truth = subspace_rank_truth;
metrics.crosstalk_matrix = crosstalk_matrix;
metrics.max_offdiagonal_crosstalk = max(off_diagonal(:));
metrics.diagonal_mixing_error = max(abs(diag(mixing) - 1));
metrics.num_svd = num_svd + mixing_info.num_svd;
end

function [distance, info] = subspace_distance_local(A, B, rank_multiplier)
[Ua, Sa, ~] = svd(A, 'econ');
[Ub, Sb, ~] = svd(B, 'econ');
[rank_a, ~] = stable_numeric_rank(diag(Sa), size(A), rank_multiplier);
[rank_b, ~] = stable_numeric_rank(diag(Sb), size(B), rank_multiplier);
Ua = Ua(:, 1:rank_a);
Ub = Ub(:, 1:rank_b);
overlap = real(norm(Ua' * Ub, 'fro') ^ 2);
distance = sqrt(max(0, 0.5 * (rank_a + rank_b - 2 * overlap)));
info = struct('rank_a', rank_a, 'rank_b', rank_b, 'num_svd', 2);
end

function [X, info] = stable_svd_solve_local( ...
    A, B, requested_rank, rank_multiplier)
[U, S, V] = svd(A, 'econ');
singular_values = diag(S);
[effective_rank, threshold] = stable_numeric_rank( ...
    singular_values, size(A), rank_multiplier);
if effective_rank == 0
    X = complex(zeros(size(A, 2), size(B, 2), 'like', A));
else
    X = V(:, 1:effective_rank) * ...
        ((U(:, 1:effective_rank)' * B) ./ ...
        singular_values(1:effective_rank));
end
info = struct('effective_rank', effective_rank, ...
    'requested_rank', requested_rank, 'rank_threshold', threshold, ...
    'num_svd', 1);
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('evaluate_group_recovery_against_truth:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('evaluate_group_recovery_against_truth:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('evaluate_group_recovery_against_truth:RankMultiplier', ...
        'opts.rank_multiplier must be positive and finite.');
end
end

function validate_inputs_local(Xphi_hat, Ce_hat, Ge_hat, truth)
if ~(iscell(Xphi_hat) && ~isempty(Xphi_hat) && ...
        isstruct(truth) && isscalar(truth) && ...
        isfield(truth, 'Xphi') && isfield(truth, 'Ce_recovery') && ...
        isfield(truth, 'Ge') && iscell(truth.Xphi) && ...
        numel(truth.Xphi) == numel(Xphi_hat))
    error('evaluate_group_recovery_against_truth:Inputs', ...
        'The estimate and test-only truth bundle are inconsistent.');
end
if ~isequal(size(Ce_hat), size(truth.Ce_recovery)) || ...
        ~isequal(size(Ge_hat), size(truth.Ge)) || ...
        any(~isfinite(Ce_hat(:))) || any(~isfinite(Ge_hat(:))) || ...
        any(~isfinite(truth.Ce_recovery(:))) || ...
        any(~isfinite(truth.Ge(:)))
    error('evaluate_group_recovery_against_truth:MatrixShape', ...
        'Estimated and test-only truth matrices must be finite and conformable.');
end
for q = 1:numel(Xphi_hat)
    if ~isequal(size(Xphi_hat{q}), size(truth.Xphi{q})) || ...
            any(~isfinite(Xphi_hat{q}(:))) || ...
            any(~isfinite(truth.Xphi{q}(:)))
        error('evaluate_group_recovery_against_truth:GroupShape', ...
            'Each recovered group must match its test-only reference shape.');
    end
end
end
