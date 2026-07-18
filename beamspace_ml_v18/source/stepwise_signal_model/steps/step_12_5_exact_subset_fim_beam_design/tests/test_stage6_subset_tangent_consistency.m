function table_out = test_stage6_subset_tangent_consistency(context, subset_rows)
%TEST_STAGE6_SUBSET_TANGENT_CONSISTENCY Recheck Stage 6 local identities.

if nargin < 2 || isempty(subset_rows)
    family = context.plan.subset_family;
    masks = [4,4;4,14;14,4;14,14;31,31];
    subset_rows = family(false(height(family), 1), :);
    for index = 1:size(masks, 1)
        match = family.elevation_mask_integer == masks(index, 1) & ...
            family.azimuth_mask_integer == masks(index, 2);
        subset_rows = [subset_rows; family(match, :)]; %#ok<AGROW>
    end
end
direction = [1;1] / sqrt(2);
separation_rad = deg2rad(0.01);
center = [8,10];
errors = zeros(height(subset_rows), 1);
case_id = strings(height(subset_rows), 1);
for row_index = 1:height(subset_rows)
    mask_e = subset_rows.elevation_mask_integer(row_index);
    mask_a = subset_rows.azimuth_mask_integer(row_index);
    channels = reshape(find(bitget(mask_e, 1:5)).' + ...
        (find(bitget(mask_a, 1:5)).' - 1).' * 5, 1, []);
    channels = channels(:).';
    model = build_exact_subset_model(context.plan.pool, channels, ...
        context.noise_models{1}, struct());
    center_manifold = build_stage7_element_manifold(center, ...
        context.plan.pool, context.cfg);
    offset_deg = rad2deg(separation_rad * direction / 2).';
    minus_manifold = build_stage7_element_manifold(center - offset_deg, ...
        context.plan.pool, context.cfg);
    plus_manifold = build_stage7_element_manifold(center + offset_deg, ...
        context.plan.pool, context.cfg);
    P = model.T_I * model.W_I';
    g0 = P * center_manifold.A;
    J = P * [center_manifold.dA_az, center_manifold.dA_el];
    G2 = [P * minus_manifold.A, P * plus_manifold.A];
    singular_values = svd(G2, 'econ');
    if numel(singular_values) < 2
        sigma2_sq = 0;
    else
        sigma2_sq = singular_values(2) ^ 2;
    end
    projector = eye(numel(g0)) - g0 * g0' / (g0' * g0);
    tangent = real(J' * projector * J);
    prediction = 0.5 * separation_rad ^ 2 * real(direction' * tangent * direction);
    g_minus = G2(:, 1);
    g_plus = G2(:, 2);
    rho = abs(g_minus' * g_plus) / (norm(g_minus) * norm(g_plus));
    coherence = 1 - rho ^ 2;
    coherence_prediction = separation_rad ^ 2 * ...
        real(direction' * tangent * direction) / norm(g0) ^ 2;
    if prediction <= 1e-18
        errors(row_index) = abs(sigma2_sq);
    else
        sigma_error = abs(sigma2_sq / prediction - 1);
        coherence_error = abs(coherence / coherence_prediction - 1);
        gram_condition = cond([g_minus / norm(g_minus), ...
            g_plus / norm(g_plus)]' * [g_minus / norm(g_minus), ...
            g_plus / norm(g_plus)]);
        gram_prediction = 4 * norm(g0) ^ 2 / ...
            (separation_rad ^ 2 * real(direction' * tangent * direction));
        gram_error = abs(gram_condition / gram_prediction - 1);
        errors(row_index) = max([sigma_error, coherence_error, gram_error]);
    end
    case_id(row_index) = subset_rows.subset_id(row_index);
end
table_out = stage7_test_table(case_id, errors, 0.01, errors <= 0.01);
end
