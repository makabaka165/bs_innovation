function [comparison, summary, keypoints] = ...
    run_stage7_keypoint_comparison_override( ...
    repo_dir, result_dir, metric, column_name, replacement)
%RUN_STAGE7_KEYPOINT_COMPARISON_OVERRIDE Compare one synthetic keypoint edit.

path_now = fullfile(result_dir, 'stage7_keypoints.csv');
options = detectImportOptions(path_now, 'TextType', 'string');
options = setvartype(options, {'metric','value','unit','status'}, 'string');
keypoints = readtable(path_now, options);
metric = string(metric);
column_name = char(string(column_name));
selected = string(keypoints.metric) == metric;
if nnz(selected) ~= 1 || ...
        ~ismember(column_name, keypoints.Properties.VariableNames)
    error('run_stage7_keypoint_comparison_override:Fixture', ...
        'The requested keypoint fixture edit is invalid.');
end
values = keypoints.(column_name);
values(selected) = replacement;
keypoints.(column_name) = values;
opts = struct('unit_test_mode', true, ...
    'current_tables_override', struct('stage7_keypoints', keypoints));
[comparison, summary] = compare_stage7_core_results_to_commit( ...
    repo_dir, result_dir, opts);
end
