function result = test_applicability_counts(fixture)
%TEST_APPLICABILITY_COUNTS Verify exact structural cardinalities.

counts = zeros(4, 1);
for trial_index = 1:height(fixture.registry)
    spec = fixture.registry(trial_index, :);
    for method_index = 1:4
        rule = stage8_k2_wacb_applicability( ...
            spec, fixture.context.constants.method_ids(method_index));
        counts(method_index) = counts(method_index) + double(rule.applicable);
    end
end
assert(isequal(counts, [1120;1260;630;630]) && ...
    height(fixture.registry) * 4 == 6720, ...
    'test_applicability_counts:Counts', ...
    'Registered applicability or new-row count changed.');
result = struct('pass', true, 'counts', counts, 'new_row_count', 6720);
end
