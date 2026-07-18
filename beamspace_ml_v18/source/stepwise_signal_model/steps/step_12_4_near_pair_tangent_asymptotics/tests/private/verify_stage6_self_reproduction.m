function [checks, summary] = verify_stage6_self_reproduction( ...
    first_snapshot_dir, second_snapshot_dir, registry, opts)
%VERIFY_STAGE6_SELF_REPRODUCTION Compare independent stage-6 snapshots.

if nargin < 4 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
validate_inputs_local(first_snapshot_dir, second_snapshot_dir, registry);
[first_manifest, first_bundle] = build_stage6_evidence_manifest( ...
    first_snapshot_dir, registry, struct('validation_scope', "CORE_RUNNER", ...
    'allow_missing_self_referential_artifacts', true));
[second_manifest, second_bundle] = build_stage6_evidence_manifest( ...
    second_snapshot_dir, registry, struct('validation_scope', "CORE_RUNNER", ...
    'allow_missing_self_referential_artifacts', true));
[numeric_comparison, numeric_summary] = ...
    compare_stage6_evidence_directories(first_snapshot_dir, ...
    second_snapshot_dir, opts.comparison_contract, ...
    struct('allow_expected_identity_change', false));

first_provenance = read_single_table_local(first_snapshot_dir, ...
    'results/stage6_provenance_contract.csv');
second_provenance = read_single_table_local(second_snapshot_dir, ...
    'results/stage6_provenance_contract.csv');
first_keypoints = read_single_table_local(first_snapshot_dir, ...
    'results/stage6_keypoints.csv');
second_keypoints = read_single_table_local(second_snapshot_dir, ...
    'results/stage6_keypoints.csv');

rows = cell(0, 1);
append_check_local("runner_completed", "1 in both snapshots", ...
    pair_text_local(keypoint_value_local(first_keypoints, ...
    'stage6_overall_pass'), keypoint_value_local(second_keypoints, ...
    'stage6_overall_pass')), "CORE_RUNNER", ...
    keypoint_is_one_local(first_keypoints, 'stage6_overall_pass') && ...
    keypoint_is_one_local(second_keypoints, 'stage6_overall_pass') && ...
    all(first_manifest.pass_flag) && all(second_manifest.pass_flag));
append_check_local("baseline_ancestor_pass", "1 in both snapshots", ...
    pair_text_local(table_value_local(first_provenance, ...
    'baseline_ancestor_flag'), table_value_local(second_provenance, ...
    'baseline_ancestor_flag')), "PROVENANCE", ...
    table_flag_local(first_provenance, 'baseline_ancestor_flag') && ...
    table_flag_local(second_provenance, 'baseline_ancestor_flag'));

hash_fields = { ...
    'source_tree_hash_match', 'stage6_source_tree_hash'; ...
    'dependency_tree_hash_match', 'stage6_dependency_tree_hash'; ...
    'controls_hash_match', 'stage6_controls_hash'; ...
    'measurement_plan_hash_match', 'stage6_measurement_plan_hash'; ...
    'experiment_plan_hash_match', 'stage6_experiment_plan_hash'; ...
    'provenance_hash_match', 'stage6_provenance_hash'};
for index = 1:size(hash_fields, 1)
    first_value = table_value_local(first_provenance, hash_fields{index, 2});
    second_value = table_value_local(second_provenance, hash_fields{index, 2});
    append_check_local(hash_fields{index, 1}, first_value, second_value, ...
        "PROVENANCE", strcmp(first_value, second_value) && ...
        ~strcmp(first_value, '<missing>'));
end

append_check_local("numeric_evidence_match", "PASS", ...
    char(numeric_summary.comparison_status(1)), "NUMERIC_EVIDENCE", ...
    numeric_summary.pass_flag(1) && all(numeric_comparison.pass_flag));
first_theory = unique_column_text_local(first_keypoints, 'theory_status');
second_theory = unique_column_text_local(second_keypoints, 'theory_status');
append_check_local("theory_status_match", first_theory, second_theory, ...
    "THEORY_STATUS", strcmp(first_theory, second_theory) && ...
    ~strcmp(first_theory, '<missing>'));
first_null = unique_column_text_local(first_keypoints, 'physical_null_status');
second_null = unique_column_text_local(second_keypoints, 'physical_null_status');
append_check_local("physical_null_status_match", first_null, second_null, ...
    "PHYSICAL_NULL_STATUS", strcmp(first_null, second_null) && ...
    ~strcmp(first_null, '<missing>'));

first_set = sort(first_manifest.relative_path( ...
    first_manifest.included_in_deterministic_bundle & ...
    first_manifest.file_exists_flag));
second_set = sort(second_manifest.relative_path( ...
    second_manifest.included_in_deterministic_bundle & ...
    second_manifest.file_exists_flag));
append_check_local("deterministic_artifact_set_match", ...
    strjoin(first_set, ';'), strjoin(second_set, ';'), ...
    "DETERMINISTIC_BUNDLE", isequal(first_set, second_set));
artifact_paths = union(first_set, second_set, 'sorted');
for artifact_index = 1:numel(artifact_paths)
    path_now = artifact_paths(artifact_index);
    first_rows = first_manifest.relative_path == path_now & ...
        first_manifest.included_in_deterministic_bundle & ...
        first_manifest.file_exists_flag;
    second_rows = second_manifest.relative_path == path_now & ...
        second_manifest.included_in_deterministic_bundle & ...
        second_manifest.file_exists_flag;
    if nnz(first_rows) == 1
        first_hash = first_manifest.sha256(first_rows);
    else
        first_hash = "MISSING";
    end
    if nnz(second_rows) == 1
        second_hash = second_manifest.sha256(second_rows);
    else
        second_hash = "MISSING";
    end
    append_check_local("deterministic_artifact_hash:" + path_now, ...
        first_hash, second_hash, "DETERMINISTIC_ARTIFACT", ...
        first_hash == second_hash && first_hash ~= "MISSING");
end
first_bundle_hash = first_bundle.stage6_evidence_bundle_hash(1);
second_bundle_hash = second_bundle.stage6_evidence_bundle_hash(1);
append_check_local("deterministic_bundle_hash_match", first_bundle_hash, ...
    second_bundle_hash, "DETERMINISTIC_BUNDLE", ...
    strcmp(first_bundle_hash, second_bundle_hash) && ...
    first_bundle.pass_flag(1) && second_bundle.pass_flag(1));

append_check_local("stage5_frozen_match", ...
    frozen_text_local(first_keypoints, 'stage5'), ...
    frozen_text_local(second_keypoints, 'stage5'), "FROZEN_BASELINE", ...
    frozen_pass_local(first_keypoints, 'stage5') && ...
    frozen_pass_local(second_keypoints, 'stage5') && ...
    strcmp(frozen_text_local(first_keypoints, 'stage5'), ...
    frozen_text_local(second_keypoints, 'stage5')));
append_check_local("step11_frozen_match", ...
    frozen_text_local(first_keypoints, 'step11'), ...
    frozen_text_local(second_keypoints, 'step11'), "FROZEN_BASELINE", ...
    frozen_pass_local(first_keypoints, 'step11') && ...
    frozen_pass_local(second_keypoints, 'step11') && ...
    strcmp(frozen_text_local(first_keypoints, 'step11'), ...
    frozen_text_local(second_keypoints, 'step11')));

checks = struct2table(vertcat(rows{:}));
check_count = height(checks);
failed_check_count = nnz(~checks.pass_flag);
if failed_check_count == 0
    self_reproduction_status = "PASS";
else
    self_reproduction_status = "FAIL";
end
pass_flag = failed_check_count == 0;
summary = table(check_count, failed_check_count, first_bundle_hash, ...
    second_bundle_hash, self_reproduction_status, pass_flag);

    function append_check_local(id, expected, observed, scope, pass)
        rows{end + 1, 1} = struct('check_id', string(id), ...
            'expected_value', string(expected), ...
            'observed_value', string(observed), ...
            'comparison_scope', string(scope), ...
            'pass_flag', logical(pass));
    end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('verify_stage6_self_reproduction:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'comparison_contract'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('verify_stage6_self_reproduction:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'comparison_contract')
    opts.comparison_contract = build_stage6_reproduction_comparison_contract();
end
if ~istable(opts.comparison_contract)
    error('verify_stage6_self_reproduction:ComparisonContract', ...
        'comparison_contract must be a table.');
end
end

function validate_inputs_local(first_dir, second_dir, registry)
if isstring(first_dir), first_dir = char(first_dir); end
if isstring(second_dir), second_dir = char(second_dir); end
if ~(ischar(first_dir) && isrow(first_dir) && exist(first_dir, 'dir') == 7 && ...
        ischar(second_dir) && isrow(second_dir) && ...
        exist(second_dir, 'dir') == 7 && istable(registry))
    error('verify_stage6_self_reproduction:Inputs', ...
        'Two existing snapshot directories and a registry are required.');
end
first_canonical = char(java.io.File(first_dir).getCanonicalPath());
second_canonical = char(java.io.File(second_dir).getCanonicalPath());
if strcmpi(first_canonical, second_canonical)
    error('verify_stage6_self_reproduction:IndependentSnapshots', ...
        'The snapshots must be distinct directories.');
end
end

function table_out = read_single_table_local(root, relative)
path_now = fullfile(root, relative);
if exist(path_now, 'file') ~= 2
    table_out = table();
else
    table_out = readtable(path_now, 'TextType', 'string');
end
end

function value = table_value_local(table_now, column_name)
if isempty(table_now) || ...
        ~ismember(column_name, table_now.Properties.VariableNames) || ...
        height(table_now) ~= 1
    value = '<missing>';
else
    value = scalar_text_local(table_now.(column_name), 1);
end
end

function flag = table_flag_local(table_now, column_name)
value = table_value_local(table_now, column_name);
flag = strcmp(value, '1') || strcmpi(value, 'true');
end

function value = keypoint_value_local(table_now, metric)
if isempty(table_now) || ~all(ismember({'metric','value'}, ...
        table_now.Properties.VariableNames))
    value = '<missing>';
    return;
end
rows = string(table_now.metric) == string(metric);
if nnz(rows) ~= 1, value = '<missing>'; ...
else, value = scalar_text_local(table_now.value(rows), 1); end
end

function flag = keypoint_is_one_local(table_now, metric)
value = keypoint_value_local(table_now, metric);
flag = strcmp(value, '1') || strcmp(value, '1.0') || strcmpi(value, 'true');
end

function value = unique_column_text_local(table_now, column_name)
if isempty(table_now) || ...
        ~ismember(column_name, table_now.Properties.VariableNames)
    value = '<missing>';
    return;
end
values = unique(string(table_now.(column_name)));
values(ismissing(values)) = [];
if numel(values) ~= 1, value = '<nonunique>'; ...
else, value = char(values(1)); end
end

function value = frozen_text_local(table_now, prefix)
count = keypoint_value_local(table_now, [prefix, '_frozen_file_count']);
mismatch = keypoint_value_local(table_now, ...
    [prefix, '_frozen_hash_mismatch_count']);
value = sprintf('files=%s;mismatches=%s', count, mismatch);
end

function flag = frozen_pass_local(table_now, prefix)
count = keypoint_value_local(table_now, [prefix, '_frozen_file_count']);
mismatch = keypoint_value_local(table_now, ...
    [prefix, '_frozen_hash_mismatch_count']);
flag = ~strcmp(count, '<missing>') && strcmp(mismatch, '0');
end

function text = pair_text_local(first, second)
text = sprintf('first=%s;second=%s', first, second);
end

function text = scalar_text_local(values, index)
value = values(index, :);
if iscell(value)
    value = value{1};
end
if isstring(value)
    if ismissing(value)
        text = '<missing>';
    else
        text = char(value);
    end
elseif ischar(value)
    text = value;
elseif islogical(value)
    text = char(string(double(value)));
elseif isnumeric(value)
    if isempty(value)
        text = '';
    elseif isnan(value)
        text = 'NaN';
    elseif isinf(value) && value > 0
        text = 'Inf';
    elseif isinf(value)
        text = '-Inf';
    else
        text = sprintf('%.17g', double(value));
    end
else
    text = char(string(value));
end
end
