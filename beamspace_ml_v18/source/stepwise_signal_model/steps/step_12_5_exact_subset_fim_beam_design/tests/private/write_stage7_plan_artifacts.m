function outputs = write_stage7_plan_artifacts(plan, result_dir)
%WRITE_STAGE7_PLAN_ARTIFACTS Persist the pre-FIM frozen registries.

if exist(result_dir, 'dir') ~= 7
    mkdir(result_dir);
end
hash_names = string(fieldnames(plan.hashes));
hash_values = strings(numel(hash_names), 1);
for index = 1:numel(hash_names)
    hash_values(index) = string(plan.hashes.(hash_names(index)));
end
registry_key = ["baseline_commit";"runtime_head_commit"; ...
    "origin_main_commit";"matlab_release";"phase_factor"; ...
    "plan_freeze_status";hash_names];
registry_value = [string(plan.baseline_commit); ...
    string(plan.runtime_head_commit);string(plan.origin_main_commit); ...
    string(plan.matlab_release);string(plan.phase_factor); ...
    string(plan.plan_freeze_status);hash_values];
registry = table(registry_key, registry_value);

outputs = struct();
outputs.plan_registry = fullfile(result_dir, 'stage7_plan_registry.csv');
outputs.candidate_pool = fullfile(result_dir, 'stage7_candidate_pool.csv');
outputs.subset_family = fullfile(result_dir, 'stage7_subset_family.csv');
outputs.source_profiles = fullfile(result_dir, 'stage7_source_profile_registry.csv');
outputs.design_scenarios = fullfile(result_dir, 'stage7_design_scenarios.csv');
outputs.validation_scenarios = fullfile(result_dir, 'stage7_validation_scenarios.csv');
outputs.fim_holdout_scenarios = ...
    fullfile(result_dir, 'stage7_fim_holdout_scenarios.csv');
outputs.finite_sample_plan = fullfile(result_dir, 'stage7_finite_sample_plan.csv');
writetable(registry, outputs.plan_registry);
writetable(plan.pool.table, outputs.candidate_pool);
writetable(plan.subset_family, outputs.subset_family);
writetable(plan.source_profiles, outputs.source_profiles);
writetable(plan.design_scenarios, outputs.design_scenarios);
writetable(plan.validation_scenarios, outputs.validation_scenarios);
writetable(plan.fim_holdout_scenarios, outputs.fim_holdout_scenarios);
writetable(plan.finite_sample_plan, outputs.finite_sample_plan);
end
