function result = test_stage8_no_chi_square_main_threshold(step_dir)
%TEST_STAGE8_NO_CHI_SQUARE_MAIN_THRESHOLD Ensure no ordinary main cutoff.

files = dir(fullfile(step_dir, 'common', '**', '*.m'));
contains_main_cutoff = false;
for index = 1:numel(files)
    text_now = lower(fileread(fullfile(files(index).folder, files(index).name)));
    contains_main_cutoff = contains_main_cutoff || contains(text_now, 'chi2inv');
end
plan = build_stage8_calibration_plan();
pass = ~contains_main_cutoff && strcmp(plan.threshold_policy, ...
    'ONE_GLOBAL_THRESHOLD_PER_FIXED_MEASUREMENT_CONFIG');
assert(pass, 'test_stage8_no_chi_square_main_threshold:Failed', ...
    'An ordinary chi-square cutoff entered the main threshold path.');
result = table(pass, ...
    'VariableNames', {'pass_flag'});
end
