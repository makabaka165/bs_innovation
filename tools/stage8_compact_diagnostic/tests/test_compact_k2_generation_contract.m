function result = test_compact_k2_generation_contract(repo_dir)
%TEST_COMPACT_K2_GENERATION_CONTRACT Exercise the four C2 generation cases.

tool_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(tool_root, 'matlab'));
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
context = stage8_compact_context(repo_dir, false);
registry = context.compact_registry;
selectors = {1,"WHITE",1; 4,"STAGE5_TOEPLITZ_CORRELATED",3; ...
    8,"WHITE",5; 8,"STAGE5_TOEPLITZ_CORRELATED",7};
hashes = strings(size(selectors, 1), 1);
for index = 1:size(selectors, 1)
    spec = registry(registry.trial_type == "K2" & ...
        registry.L == selectors{index, 1} & ...
        registry.noise_profile_id == selectors{index, 2} & ...
        registry.profile_id == selectors{index, 3}, :);
    assert(height(spec) == 1);
    [left, left_contract] = stage8_compact_generate_k2_trial(spec, context);
    [right, right_contract] = stage8_compact_generate_k2_trial(spec, context);
    assert(isequal(num2hex(real(left.Y_element)), ...
        num2hex(real(right.Y_element))));
    assert(isequal(num2hex(imag(left.Y_element)), ...
        num2hex(imag(right.Y_element))));
    assert(strcmp(left.element_trial_hash, right.element_trial_hash));
    assert(isequal(left_contract, right_contract));
    assert(left_contract.source_total_energy_contract_pass);
    assert(left_contract.secondary_power_contract_pass);
    assert(left_contract.correlation_contract_pass);
    assert(left_contract.endpoints_in_domain_pass);
    assert(left_contract.seed_roles_separated_pass);
    assert(~left_contract.truth_used_in_fit_flag);
    assert(~left_contract.truth_used_in_classifier_flag);
    if spec.L == 1, assert(left_contract.correlation_magnitude == 1); end
    hashes(index) = string(left.element_trial_hash);
end
result = struct('pass', true, 'trial_count', numel(hashes), ...
    'element_trial_hashes', hashes);
clear path_cleanup
end
