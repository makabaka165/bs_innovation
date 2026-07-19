function result = test_stage8_no_c05_topk_gap_rules(step_dir)
%TEST_STAGE8_NO_C05_TOPK_GAP_RULES Scan only active Stage8 common code.

files = dir(fullfile(step_dir, 'common', '**', '*.m'));
forbidden_count = 0;
for index = 1:numel(files)
    text_now = lower(fileread(fullfile(files(index).folder, files(index).name)));
    forbidden_count = forbidden_count + contains(text_now, 'c05') + ...
        contains(text_now, 'topk') + contains(text_now, 'score_gap');
end
pass = forbidden_count == 0;
assert(pass, 'test_stage8_no_c05_topk_gap_rules:Failed', ...
    'Active Stage8 code reintroduced a forbidden empirical search rule.');
result = table(pass, forbidden_count, ...
    'VariableNames', {'pass_flag','forbidden_count'});
end
