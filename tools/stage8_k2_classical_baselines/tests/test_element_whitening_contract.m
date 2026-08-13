function result = test_element_whitening_contract()
%TEST_ELEMENT_WHITENING_CONTRACT Verify model.Rn_elem maps to identity.

test_dir = fileparts(mfilename('fullpath'));
repo_dir = fileparts(fileparts(fileparts(test_dir)));
scope = stage8_k2_cb_add_paths(repo_dir); %#ok<NASGU>
context = stage8_k2_cb_build_context(repo_dir);
errors = zeros(numel(context.constants.noise_profile_ids), 1);
for index = 1:numel(context.constants.noise_profile_ids)
    model = resolve_stage8_measurement_model( ...
        context.plan.measurement_model_registry, ...
        context.primary_measurement_config_id, ...
        context.constants.noise_profile_ids(index));
    dummy = complex(zeros(size(model.Rn_elem, 1), 2));
    [white, info] = stage8_k2_cb_whiten_element_data(dummy, model);
    errors(index) = info.whitening_error;
    assert(all(white(:) == 0) && info.numeric_rank == size(model.Rn_elem, 1), ...
        'test_element_whitening_contract:Data', ...
        'Element whitener violates its dimension or zero-data contract.');
end
assert(all(errors <= 1e-8), ...
    'test_element_whitening_contract:Identity', ...
    'An element covariance did not whiten to identity.');
result = struct('pass', true, 'whitening_errors', errors);
fprintf('test_element_whitening_contract PASS\n');
end
