function result_table = test_step12_has_no_legacy_echo_dependency(step_dir)
%TEST_STEP12_HAS_NO_LEGACY_ECHO_DEPENDENCY Scan the active Step12.1 path.

files = dir(fullfile(step_dir, 'common', '**', '*.m'));
runner = dir(fullfile(step_dir, 'run_step12_1_sequential_dbf_validation.m'));
files = [files; runner];
combined = '';
for idx = 1:numel(files)
    combined = [combined, newline, fileread(fullfile(files(idx).folder, files(idx).name))]; %#ok<AGROW>
end

rule = ["no_echo_elem_call"; "no_echo_elem_cube_call"; ...
        "no_four_pi_over_lambda"; "no_phasefactor_equals_2"; ...
        "no_spatial_phase_factor_equals_2"; "receive_builder_called"];
patterns = {'(?<![A-Za-z0-9_])echo_elem\s*\(', ...
            '(?<![A-Za-z0-9_])echo_elem_cube\s*\(', ...
            '4\s*\*\s*pi\s*/\s*lambda', ...
            'PhaseFactor\s*=\s*2', ...
            'spatialPhaseFactor\s*=\s*2', ...
            'build_receive_cyl_steering_vec\s*\('};
hit_count = zeros(numel(rule), 1);
pass_flag = false(numel(rule), 1);
phase_factor = ones(numel(rule), 1);
for idx = 1:numel(rule)
    hit_count(idx) = numel(regexp(combined, patterns{idx}, 'match'));
    if idx < numel(rule)
        pass_flag(idx) = hit_count(idx) == 0;
    else
        pass_flag(idx) = hit_count(idx) >= 1;
    end
end

result_table = table(rule, hit_count, pass_flag, phase_factor);
assert(all(pass_flag), 'test_step12_has_no_legacy_echo_dependency:Failed', ...
    'The active Step12.1 source contains a forbidden legacy dependency.');
end
