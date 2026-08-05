function result = test_truth_isolation(fixture)
%TEST_TRUTH_ISOLATION Ensure every prohibited fit field is rejected.

spec = fixture.registry(1, :);
resources = stage8_k2_wacb_test_resources(fixture.context, "WHITE");
[trial, ~] = stage8_k2_wacb_reconstruct_trial(spec, fixture.context);
rules = repmat(struct('applicable', false, 'status', "", ...
    'uses_registered_scenario_flag', false), 4, 1);
for index = 1:4
    rules(index) = stage8_k2_wacb_applicability( ...
        spec, fixture.context.constants.method_ids(index));
end
base = struct('Y_element', trial.Y_element, 'model', trial.model, ...
    'L', double(spec.L), 'resource_entry', resources.structured_entry, ...
    'music_resources', resources, 'applicability', rules);
forbidden = {'truth','truth_angles_deg','profile_id','profile_label', ...
    'tangent_result','core_result','full4d_result','RMSE', ...
    'working_region_label','k2_projected_snr','white_snr_target_db', ...
    'other_method_estimates'};
for index = 1:numel(forbidden)
    candidate = base;
    candidate.(forbidden{index}) = 1;
    rejected = false;
    try
        stage8_k2_wacb_fit_new_methods(candidate, fixture.context.constants);
    catch exception
        rejected = strcmp(exception.identifier, ...
            'stage8_k2_wacb_fit_new_methods:TruthIsolation');
    end
    assert(rejected, 'test_truth_isolation:Accepted', ...
        'A prohibited fit field was accepted: %s', forbidden{index});
end
result = struct('pass', true, 'rejected_field_count', numel(forbidden), ...
    'truth_leakage_count', 0);
end
