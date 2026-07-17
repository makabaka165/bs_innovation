function result_table = test_step12_2_has_no_fixed_ridge(step_dir)
%TEST_STEP12_2_HAS_NO_FIXED_RIDGE Scan the new common source path.

files = dir(fullfile(step_dir, 'common', '**', '*.m'));
combined = '';
for idx = 1:numel(files)
    combined = [combined, newline, ...
        fileread(fullfile(files(idx).folder, files(idx).name))]; %#ok<AGROW>
end

rule = ["no_fixed_1e_10"; "no_normal_equation_product"; ...
    "no_explicit_inv"; "no_pinv"; "no_2x2_determinant_formula"; ...
    "no_legacy_score_call"];
patterns = {'1e-10', ...
    'G\s*''\s*\*\s*G', ...
    '(?<![A-Za-z0-9_])inv\s*\(', ...
    '(?<![A-Za-z0-9_])pinv\s*\(', ...
    's11\s*\*\s*s22', ...
    '(?<![A-Za-z0-9_])beamspace_dml_score\s*\('};
hit_count = zeros(numel(rule), 1);
pass_flag = false(numel(rule), 1);
phase_factor = ones(numel(rule), 1);
for idx = 1:numel(rule)
    hit_count(idx) = numel(regexp(combined, patterns{idx}, 'match'));
    pass_flag(idx) = hit_count(idx) == 0;
end

result_table = table(rule, hit_count, pass_flag, phase_factor);
assert(all(pass_flag), 'test_step12_2_has_no_fixed_ridge:Failed', ...
    'The Step12.2 common path contains a forbidden legacy score pattern.');
end
