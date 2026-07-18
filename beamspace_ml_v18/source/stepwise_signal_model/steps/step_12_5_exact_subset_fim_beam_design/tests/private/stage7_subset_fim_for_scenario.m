function [fim, model] = stage7_subset_fim_for_scenario( ...
    context, scenario_index, mask_e, mask_a)
%STAGE7_SUBSET_FIM_FOR_SCENARIO Build one exact test-case FIM.

channels = reshape(find(bitget(mask_e, 1:5)).' + ...
    (find(bitget(mask_a, 1:5)).' - 1).' * 5, 1, []);
channels = channels(:).';
scenario = context.scenarios(scenario_index);
model = build_exact_subset_model(context.plan.pool, channels, ...
    context.noise_models{scenario.noise_index}, struct());
T = model.T_I;
G = T * scenario.raw_G0(channels, :);
dG = struct('azimuth', T * scenario.raw_dG0_az(channels, :), ...
    'elevation', T * scenario.raw_dG0_el(channels, :));
fim = effective_deterministic_fim(G, dG, scenario.S, ...
    context.plan.controls.sigma2_fim, struct());
end
