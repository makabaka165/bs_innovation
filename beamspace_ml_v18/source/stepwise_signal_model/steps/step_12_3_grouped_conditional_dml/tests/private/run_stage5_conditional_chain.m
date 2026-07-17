function chain = run_stage5_conditional_chain(fixture, eta_condition_deg, source_name)
%RUN_STAGE5_CONDITIONAL_CHAIN Run all oracle-known Kq group searches.

if numel(eta_condition_deg) ~= fixture.Q
    error('run_stage5_conditional_chain:ElevationCount', ...
        'eta_condition_deg must contain one value per oracle group.');
end
chain = struct();
chain.source_name = char(source_name);
chain.eta_condition_deg = eta_condition_deg(:).';
chain.group_estimate = cell(fixture.Q, 1);
chain.group_debug = cell(fixture.Q, 1);
chain.group_data = cell(fixture.Q, 1);
chain.group_model = cell(fixture.Q, 1);
chain.group_prepare_debug = cell(fixture.Q, 1);
chain.initial_angles_deg = zeros(0, 2);
chain.num_score_eval = 0;
chain.num_svd = 0;
chain.num_eig = 0;
chain.runtime_sec = 0;
chain.precompute_runtime_sec = 0;
chain.online_runtime_sec = 0;
chain.returned_flag = true;

for q = 1:fixture.Q
    precompute_tic = tic;
    if isempty(fixture.Xphi_hat)
        Xphi_q = complex(zeros(numel(fixture.aperture_index), ...
            size(fixture.spec.source_snapshots, 2)));
    else
        Xphi_q = fixture.Xphi_hat{q};
    end
    [Uq, bank_info] = build_fixed_conditional_azimuth_beam_bank( ...
        fixture.locked.az_beam_deg, eta_condition_deg(q), ...
        fixture.array_meta, struct('lambda', fixture.cfg.arr.lambda, ...
        'aperture_index', fixture.aperture_index, 'phase_factor', 1));
    prepare_opts = struct( ...
        'eta_condition_deg', eta_condition_deg(q), ...
        'condition_source', char(source_name), ...
        'upstream_group_support_status', fixture.stage4_est.support_status, ...
        'estimate_returned_flag', fixture.stage4_est.estimate_returned_flag, ...
        'structural_gate_pass_flag', ...
        fixture.stage4_est.structural_gate_pass_flag, ...
        'array_coordinates', bank_info.array_coordinates, ...
        'lambda', fixture.cfg.arr.lambda, ...
        'beam_bank_hash', bank_info.beam_bank_hash, 'phase_factor', 1);
    alpha_q = 1;
    if numel(fixture.noise_model.group_noise_scale) >= q && ...
            isfinite(fixture.noise_model.group_noise_scale(q)) && ...
            fixture.noise_model.group_noise_scale(q) > 0
        alpha_q = fixture.noise_model.group_noise_scale(q);
    end
    [data, model, prepare_debug] = prepare_conditional_azimuth_data( ...
        Xphi_q, Uq, fixture.Rphi_selected, alpha_q, prepare_opts);
    precompute_runtime_sec = toc(precompute_tic);
    estimate_tic = tic;
    [estimate, estimate_debug] = estimate_conditional_azimuth_dml( ...
        data, fixture.oracle_Kq(q), fixture.domain, model, struct());
    runtime_sec = toc(estimate_tic);
    estimate.runtime = runtime_sec;
    chain.group_estimate{q} = estimate;
    chain.group_debug{q} = estimate_debug;
    chain.group_data{q} = data;
    chain.group_model{q} = model;
    chain.group_prepare_debug{q} = prepare_debug;
    chain.num_score_eval = chain.num_score_eval + estimate.num_score_eval;
    chain.num_svd = chain.num_svd + estimate.num_svd;
    chain.num_eig = chain.num_eig + prepare_debug.num_eig;
    chain.runtime_sec = chain.runtime_sec + runtime_sec;
    chain.precompute_runtime_sec = chain.precompute_runtime_sec + ...
        precompute_runtime_sec;
    chain.online_runtime_sec = chain.online_runtime_sec + runtime_sec;
    chain.returned_flag = chain.returned_flag && ...
        estimate.estimate_returned_flag;
    if estimate.estimate_returned_flag
        group_angles = [estimate.az_hat_deg(:), ...
            repmat(eta_condition_deg(q), fixture.oracle_Kq(q), 1)];
        chain.initial_angles_deg = [chain.initial_angles_deg; group_angles];
    end
end
chain.runtime_sec = chain.precompute_runtime_sec + chain.online_runtime_sec;
if size(chain.initial_angles_deg, 1) == fixture.K
    chain.initial_angles_deg = canonicalize_local(chain.initial_angles_deg);
else
    chain.initial_angles_deg = NaN(fixture.K, 2);
end
end

function angles = canonicalize_local(angles)
[~, order] = sortrows([angles(:, 2), angles(:, 1)], [1, 2]);
angles = angles(order, :);
end
