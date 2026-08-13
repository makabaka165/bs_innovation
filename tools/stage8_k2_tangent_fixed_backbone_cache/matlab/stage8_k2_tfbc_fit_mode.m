function [result, diagnostics, result_checksum_hash, projection] = ...
    stage8_k2_tfbc_fit_mode(trial, context, provider, mode)
%STAGE8_K2_TFBC_FIT_MODE Run one complete Tangent-safe fixed mode.

mode = upper(char(string(mode)));
run_context = context;
run_context.fixed_registered_manifold_provider = provider;
run_context.fixed_manifold_mode = mode;
if isfield(run_context, 't4_manifold_provider')
    run_context = rmfield(run_context, 't4_manifold_provider');
end
if isfield(run_context, 'manifold_provider')
    run_context = rmfield(run_context, 'manifold_provider');
end
[result, diagnostics] = stage8_k2_tp_fit_safe( ...
    trial.Y_element, trial.model, run_context);
projection = stage8_k2_tecs_root_projection( ...
    result, diagnostics, 'CACHE_OFF_BASELINE');
result_checksum_hash = stage8_k2_tecs_sha256( ...
    'STAGE8_K2_TFBC_RESULT_V1', projection);
end
