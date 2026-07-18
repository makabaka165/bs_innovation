function table_out = test_source_matrix_power_and_correlation(context)
%TEST_SOURCE_MATRIX_POWER_AND_CORRELATION Check all registered source profiles.

profiles = context.plan.source_profiles;
metric = zeros(height(profiles) + 1, 1);
case_id = strings(height(profiles) + 1, 1);
for index = 1:height(profiles)
    [~, info] = construct_deterministic_source_matrix(2, profiles.L(index), ...
        profiles.secondary_power_db(index), ...
        profiles.correlation_magnitude(index), ...
        profiles.correlation_phase_rad(index), profiles.profile_id(index));
    metric(index) = max([info.energy_relative_error, ...
        info.power_relative_error, info.correlation_absolute_error]);
    case_id(index) = profiles.profile_id(index);
end
[~, info] = construct_deterministic_source_matrix(2, 1, -6, 1, pi/3, 'L1');
metric(end) = max([info.energy_relative_error, info.power_relative_error, ...
    info.correlation_absolute_error]);
case_id(end) = "L1_COHERENT";
table_out = stage7_test_table(case_id, metric, 1e-12, metric <= 1e-12);
end
