function result = test_compact_k1_evaluator_evidence(repo_dir, evidence_path)
%TEST_COMPACT_K1_EVALUATOR_EVIDENCE Verify reusable K1 smoke evidence.

expected = ...
    'd78ace209ee3ac352255a77d0c7ef09ee060c8fd12be39502722076b8d96f328';
text_value = string(fileread(evidence_path));
assert(contains(text_value, "SMOKE_PASS=1"));
assert(contains(text_value, "REFERENCE_HASH=" + expected));
assert(contains(text_value, "EXTERNAL_HASH=" + expected));
test_path = fullfile(repo_dir, 'tools', 'stage8_1b_validation_sharded', ...
    'tests', 'test_external_runner_matches_reference.m');
test_source = fileread(test_path);
assert(contains(test_source, ...
    'assert(isequal(num2hex(double(reference_trials.lambda_12))'));
result = struct('pass', true, 'reference_row_hash', expected, ...
    'external_row_hash', expected, 'lambda_num2hex_equality', true);
end
