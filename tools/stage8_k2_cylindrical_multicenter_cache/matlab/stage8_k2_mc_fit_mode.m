function [result, diagnostics, projection, checksum, runtime_sec] = ...
    stage8_k2_mc_fit_mode(trial, base_context, provider, adapter, mode)
%STAGE8_K2_MC_FIT_MODE Run one complete center-aware Tangent-safe root.

mode = upper(char(string(mode)));
context = base_context;
context.plan.local_domain = trial.local_domain;
context.stage5_locked = trial.stage5_locked;
context.fixed_manifold_mode = mode;
context.fixed_registered_manifold_provider = provider;
context.fixed_registered_center_adapter = adapter;
if isfield(context, 't4_manifold_provider')
    context = rmfield(context, 't4_manifold_provider');
end
if isfield(context, 'manifold_provider')
    context = rmfield(context, 'manifold_provider');
end
clock = tic;
[result, diagnostics] = stage8_k2_tp_fit_safe( ...
    trial.Y_element, trial.model, context);
runtime_sec = toc(clock);
projection = stage8_k2_tecs_root_projection( ...
    result, diagnostics, 'CACHE_ON_DECISION');
checksum = stage8_k2_tecs_sha256( ...
    'STAGE8_K2_MC_RESULT_V1', projection);
end
