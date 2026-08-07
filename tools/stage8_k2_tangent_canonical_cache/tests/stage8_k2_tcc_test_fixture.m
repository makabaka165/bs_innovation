function fixture = stage8_k2_tcc_test_fixture()
%STAGE8_K2_TCC_TEST_FIXTURE Build one reusable WHITE measurement fixture.

persistent cached_fixture
if ~isempty(cached_fixture)
    fixture = cached_fixture;
    return;
end
test_dir = fileparts(mfilename('fullpath'));
repo_dir = fileparts(fileparts(fileparts(test_dir)));
context = stage8_k2_tp_build_context(repo_dir);
model = resolve_stage8_measurement_model( ...
    context.plan.measurement_model_registry, ...
    context.primary_measurement_config_id, 'WHITE');
cache_options = struct( ...
    'global_az_grid_deg', [7.4, 7.6, 7.8, 8.0, 8.2, 8.4, 8.6], ...
    'el_grid_deg', [9.8, 9.9, 10.0, 10.1, 10.2]);
[cache, cache_info] = stage8_k2_tcc_build_cache(model, cache_options);
rng_state = rng;
rng_cleanup = onCleanup(@() rng(rng_state)); %#ok<NASGU>
rng(820261, 'twister');
Z_white = randn(size(model.Tseq, 1), 8) + ...
    1i * randn(size(model.Tseq, 1), 8);
cached_fixture = struct('repo_dir', repo_dir, 'context', context, ...
    'model', model, 'cache', cache, 'cache_info', cache_info, ...
    'Z_white', Z_white);
fixture = cached_fixture;
end
