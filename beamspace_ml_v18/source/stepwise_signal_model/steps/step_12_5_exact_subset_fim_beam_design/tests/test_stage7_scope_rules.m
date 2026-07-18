function table_out = test_stage7_scope_rules(step_dir)
%TEST_STAGE7_SCOPE_RULES Enforce the registered Stage 7 implementation scope.

required = [ ...
    "README.md";"common";"common/private";"tests";"tests/private"; ...
    "results";"figures";"run_step12_5_exact_subset_fim_design.m"];
missing = false(numel(required), 1);
for index = 1:numel(required)
    path_now = fullfile(step_dir, strrep(char(required(index)), '/', filesep));
    missing(index) = exist(path_now, 'file') ~= 2 && exist(path_now, 'dir') ~= 7;
end
files = dir(fullfile(step_dir, 'common', '**', '*.m'));
reporting_files = ["build_stage7_baseline_status.m"; ...
    "write_stage7_results_bundle.m"];
files = files(~ismember(string({files.name}).', reporting_files));
forbidden = ["C05";"topK";"adaptive_W";"adaptive_B"; ...
    "greedy_combined_B7";"K=3";"persistent cache"];
counts = zeros(numel(forbidden), 1);
for file_index = 1:numel(files)
    text_now = string(fileread(fullfile(files(file_index).folder, ...
        files(file_index).name)));
    for pattern_index = 1:numel(forbidden)
        counts(pattern_index) = counts(pattern_index) + ...
            count(lower(text_now), lower(forbidden(pattern_index)));
    end
end
case_id = ["MISSING_" + required;"FORBIDDEN_" + forbidden];
metric = [double(missing);counts];
table_out = stage7_test_table(case_id, metric, 0, metric == 0);
end
