function plan = build_stage7_1_synthetic_edge_fixture(result_dir)
%BUILD_STAGE7_1_SYNTHETIC_EDGE_FIXTURE Return two groups with two trials.

plan = build_stage7_1_edge_diagnostic_plan(result_dir);
plan = plan(plan.paired_group_index <= 2, :);
plan.Nmc(:) = 2;
plan.paired_trial_count(:) = 2;
plan.common_trial_count_expected(:) = 4;
plan.method_evaluation_count_expected(:) = 12;
plan.plan_version(:) = "STAGE7_1_SYNTHETIC_EDGE_FIXTURE_V1";
end
