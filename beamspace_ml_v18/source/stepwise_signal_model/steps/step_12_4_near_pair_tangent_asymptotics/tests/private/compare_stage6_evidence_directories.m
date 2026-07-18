function [comparison, summary] = compare_stage6_evidence_directories( ...
    old_step_dir, new_step_dir, contract, opts)
%COMPARE_STAGE6_EVIDENCE_DIRECTORIES Compare two stage-6 CSV directories.

if nargin < 4 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
validate_inputs_local(old_step_dir, new_step_dir, contract);
rows = cell(0, 1);
artifact_count = contract_height_local(contract);
row_count_compared = 0;
numeric_value_count = 0;
exact_value_count = 0;
missing_artifact_count = 0;
row_key_mismatch_count = 0;
numeric_failure_count = 0;
exact_failure_count = 0;
maximum_absolute_difference = 0;
maximum_relative_difference = 0;

for artifact_index = 1:artifact_count
    item = contract_row_local(contract, artifact_index);
    old_path = fullfile(old_step_dir, char(item.relative_path));
    new_path = fullfile(new_step_dir, char(item.relative_path));
    old_exists = exist(old_path, 'file') == 2;
    new_exists = exist(new_path, 'file') == 2;
    if ~(old_exists && new_exists)
        missing_artifact_count = missing_artifact_count + 1;
        rows{end + 1, 1} = row_local(item, "", "<artifact>", ...
            "ARTIFACT_PRESENCE", value_text_local(old_exists), ...
            value_text_local(new_exists), NaN, NaN, NaN, NaN, ...
            item.numeric_absolute_tolerance, ...
            item.numeric_relative_tolerance, false, false); %#ok<AGROW>
        continue;
    end
    old_table = readtable(old_path, 'TextType', 'string');
    new_table = readtable(new_path, 'TextType', 'string');
    [old_table, old_keys, old_duplicate] = prepare_table_local(old_table, item);
    [new_table, new_keys, new_duplicate] = prepare_table_local(new_table, item);
    if old_duplicate || new_duplicate
        row_key_mismatch_count = row_key_mismatch_count + 1;
        rows{end + 1, 1} = row_local(item, "", "<row-key>", ...
            "DUPLICATE_ROW_KEY", value_text_local(old_duplicate), ...
            value_text_local(new_duplicate), NaN, NaN, NaN, NaN, ...
            0, 0, false, false); %#ok<AGROW>
        continue;
    end
    if opts.allow_expected_identity_change
        expected_change_keys = string( ...
            item.expected_identity_change_row_keys(:));
    else
        expected_change_keys = strings(0, 1);
    end
    expected_old = ismember(old_keys, expected_change_keys);
    expected_new_rows = ismember(new_keys, expected_change_keys);
    for expected_key = expected_change_keys(:).'
        old_present = any(old_keys == expected_key);
        new_present = any(new_keys == expected_key);
        if old_present || new_present
            rows{end + 1, 1} = row_local(item, expected_key, ...
                "<row>", "EXPECTED_PROVENANCE_IDENTITY_CHANGE", ...
                value_text_local(old_present), value_text_local(new_present), ...
                NaN, NaN, NaN, NaN, 0, 0, true, true); %#ok<AGROW>
        end
    end
    old_table = old_table(~expected_old, :);
    old_keys = old_keys(~expected_old);
    new_table = new_table(~expected_new_rows, :);
    new_keys = new_keys(~expected_new_rows);
    if ~isequal(old_keys, new_keys)
        row_key_mismatch_count = row_key_mismatch_count + 1;
        rows{end + 1, 1} = row_local(item, "", "<row-key-set>", ...
            "ROW_KEY_SET", strjoin(old_keys, ";"), strjoin(new_keys, ";"), ...
            NaN, NaN, NaN, NaN, 0, 0, false, false); %#ok<AGROW>
        continue;
    end
    row_count_compared = row_count_compared + numel(old_keys);

    old_names = string(old_table.Properties.VariableNames(:));
    new_names = string(new_table.Properties.VariableNames(:));
    ignored = string(item.ignored_columns(:));
    expected_new = string(item.expected_new_columns(:));
    old_active = setdiff(old_names, ignored, 'stable');
    new_active = setdiff(new_names, ignored, 'stable');
    old_only = setdiff(old_active, new_active, 'stable');
    new_only = setdiff(new_active, [old_active; expected_new], 'stable');
    for name = old_only(:).'
        exact_failure_count = exact_failure_count + 1;
        rows{end + 1, 1} = row_local(item, "", name, ...
            "COLUMN_MISSING_FROM_NEW", "PRESENT", "MISSING", ...
            NaN, NaN, NaN, NaN, 0, 0, false, false); %#ok<AGROW>
    end
    for name = new_only(:).'
        exact_failure_count = exact_failure_count + 1;
        rows{end + 1, 1} = row_local(item, "", name, ...
            "UNEXPECTED_NEW_COLUMN", "MISSING", "PRESENT", ...
            NaN, NaN, NaN, NaN, 0, 0, false, false); %#ok<AGROW>
    end
    for name = expected_new(:).'
        if ~ismember(name, old_names)
            pass = ismember(name, new_names);
            exact_value_count = exact_value_count + 1;
            exact_failure_count = exact_failure_count + double(~pass);
            rows{end + 1, 1} = row_local(item, "", name, ...
                "EXPECTED_CONTRACT_EXTENSION", "NOT_IN_OLD_CONTRACT", ...
                value_text_local(pass), NaN, NaN, NaN, NaN, ...
                0, 0, false, pass); %#ok<AGROW>
        end
    end

    comparable = intersect(old_active, new_active, 'stable');
    for column_name = comparable(:).'
        old_values = old_table.(char(column_name));
        new_values = new_table.(char(column_name));
        identity_change = ismember(column_name, ...
            string(item.expected_identity_change_columns(:)));
        exact_requested = ismember(column_name, string(item.exact_columns(:)));
        numeric_pair = isnumeric(old_values) && isnumeric(new_values) && ...
            ~islogical(old_values) && ~islogical(new_values);
        for row_index = 1:numel(old_keys)
            row_exact_requested = column_name == "value" && ...
                ismember(old_keys(row_index), ...
                string(item.exact_value_row_keys(:)));
            if identity_change && opts.allow_expected_identity_change
                exact_value_count = exact_value_count + 1;
                rows{end + 1, 1} = row_local(item, old_keys(row_index), ...
                    column_name, "EXPECTED_PROVENANCE_IDENTITY_CHANGE", ...
                    scalar_text_local(old_values, row_index), ...
                    scalar_text_local(new_values, row_index), NaN, NaN, ...
                    NaN, NaN, 0, 0, true, true); %#ok<AGROW>
            elseif numeric_pair && ~exact_requested && ~row_exact_requested
                old_numeric = double(old_values(row_index));
                new_numeric = double(new_values(row_index));
                [pass, absolute_difference, relative_difference] = ...
                    numeric_compare_local(old_numeric, new_numeric, ...
                    item.numeric_absolute_tolerance, ...
                    item.numeric_relative_tolerance);
                numeric_value_count = numeric_value_count + 1;
                numeric_failure_count = numeric_failure_count + double(~pass);
                maximum_absolute_difference = max_finite_local( ...
                    maximum_absolute_difference, absolute_difference);
                maximum_relative_difference = max_finite_local( ...
                    maximum_relative_difference, relative_difference);
                rows{end + 1, 1} = row_local(item, old_keys(row_index), ...
                    column_name, "NUMERIC_TOLERANCE", ...
                    scalar_text_local(old_values, row_index), ...
                    scalar_text_local(new_values, row_index), ...
                    old_numeric, new_numeric, absolute_difference, ...
                    relative_difference, item.numeric_absolute_tolerance, ...
                    item.numeric_relative_tolerance, false, pass); %#ok<AGROW>
            else
                old_text = scalar_text_local(old_values, row_index);
                new_text = scalar_text_local(new_values, row_index);
                pass = strcmp(old_text, new_text);
                exact_value_count = exact_value_count + 1;
                exact_failure_count = exact_failure_count + double(~pass);
                rows{end + 1, 1} = row_local(item, old_keys(row_index), ...
                    column_name, "EXACT", old_text, new_text, ...
                    NaN, NaN, NaN, NaN, 0, 0, false, pass); %#ok<AGROW>
            end
        end
    end
end

[identity_rows, identity_check_count, identity_failure_count] = ...
    validate_current_measurement_hashes_local(new_step_dir, contract);
if ~isempty(identity_rows)
    rows = [rows; identity_rows];
    exact_value_count = exact_value_count + identity_check_count;
    exact_failure_count = exact_failure_count + identity_failure_count;
end

comparison = rows_to_table_local(rows);
failure_count = missing_artifact_count + row_key_mismatch_count + ...
    numeric_failure_count + exact_failure_count;
pass_flag = failure_count == 0 && all(comparison.pass_flag);
if pass_flag, comparison_status = "PASS"; else, comparison_status = "FAIL"; end
summary = table(artifact_count, row_count_compared, numeric_value_count, ...
    exact_value_count, missing_artifact_count, row_key_mismatch_count, ...
    numeric_failure_count, exact_failure_count, ...
    maximum_absolute_difference, maximum_relative_difference, ...
    comparison_status, pass_flag);
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('compare_stage6_evidence_directories:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'allow_expected_identity_change'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('compare_stage6_evidence_directories:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'allow_expected_identity_change')
    opts.allow_expected_identity_change = true;
end
if ~(islogical(opts.allow_expected_identity_change) && ...
        isscalar(opts.allow_expected_identity_change))
    error('compare_stage6_evidence_directories:IdentityOption', ...
        'allow_expected_identity_change must be a logical scalar.');
end
end

function validate_inputs_local(old_dir, new_dir, contract)
if isstring(old_dir), old_dir = char(old_dir); end
if isstring(new_dir), new_dir = char(new_dir); end
required = {'artifact_id','relative_path','key_columns','ignored_columns', ...
    'numeric_absolute_tolerance','numeric_relative_tolerance', ...
    'exact_columns','comparison_scope','expected_identity_change_columns', ...
    'expected_new_columns','ignored_row_keys', ...
    'expected_identity_change_row_keys','exact_value_row_keys'};
if ~(ischar(old_dir) && isrow(old_dir) && exist(old_dir, 'dir') == 7 && ...
        ischar(new_dir) && isrow(new_dir) && exist(new_dir, 'dir') == 7 && ...
        istable(contract) && all(ismember(required, ...
        contract.Properties.VariableNames)))
    error('compare_stage6_evidence_directories:Inputs', ...
        'Two step directories and a valid comparison contract are required.');
end
end


function [rows, check_count, failure_count] = ...
    validate_current_measurement_hashes_local(step_dir, contract)
rows = cell(0, 1);
check_count = 0;
failure_count = 0;
registry_rows = contract.artifact_id == "measurement_hash_registry";
if nnz(registry_rows) ~= 1
    return;
end
registry_item = contract_row_local(contract, find(registry_rows, 1));
registry_path = fullfile(step_dir, char(registry_item.relative_path));
if exist(registry_path, 'file') ~= 2
    return;
end
measurement_registry = readtable(registry_path, 'TextType', 'string');
required = {'config_id','fixed_measurement_hash'};
if ~all(ismember(required, measurement_registry.Properties.VariableNames)) || ...
        numel(unique(string(measurement_registry.config_id))) ~= ...
        height(measurement_registry)
    return;
end
known_ids = string(measurement_registry.config_id);
known_hashes = string(measurement_registry.fixed_measurement_hash);
for artifact_index = 1:height(contract)
    item = contract_row_local(contract, artifact_index);
    path_now = fullfile(step_dir, char(item.relative_path));
    if exist(path_now, 'file') ~= 2, continue; end
    table_now = readtable(path_now, 'TextType', 'string');
    if ~all(ismember(required, table_now.Properties.VariableNames)), continue; end
    for row_index = 1:height(table_now)
        config_id = string(table_now.config_id(row_index));
        known = find(known_ids == config_id);
        actual = string(table_now.fixed_measurement_hash(row_index));
        if numel(known) == 1
            expected = known_hashes(known);
            pass = actual == expected;
        elseif config_id == "SYNTHETIC_ANALYTIC_NULL"
            expected = "SYNTHETIC_ANALYTIC_NULL";
            pass = actual == expected;
        else
            expected = "REGISTERED_CONFIG_ID";
            pass = false;
        end
        check_count = check_count + 1;
        failure_count = failure_count + double(~pass);
        key_text = "config_id=" + config_id;
        rows{end + 1, 1} = row_local(item, key_text, ...
            "fixed_measurement_hash", ...
            "CURRENT_MEASUREMENT_HASH_CONSISTENCY", expected, actual, ...
            NaN, NaN, NaN, NaN, 0, 0, false, pass); %#ok<AGROW>
    end
end
end

function count = contract_height_local(contract)
count = height(contract);
end

function item = contract_row_local(contract, index)
item = struct();
names = contract.Properties.VariableNames;
for name_index = 1:numel(names)
    value = contract.(names{name_index});
    if iscell(value), item.(names{name_index}) = value{index}; ...
    else, item.(names{name_index}) = value(index, :); end
end
item.artifact_id = string(item.artifact_id);
item.relative_path = replace(string(item.relative_path), '\', '/');
item.comparison_scope = string(item.comparison_scope);
end

function [table_out, keys, duplicate] = prepare_table_local(table_in, item)
names = string(table_in.Properties.VariableNames);
key_columns = string(item.key_columns(:));
if isempty(key_columns) || ~all(ismember(key_columns, names))
    table_out = table_in;
    keys = "<MISSING_KEY_COLUMN>";
    duplicate = true;
    return;
end
keys = strings(height(table_in), 1);
for row_index = 1:height(table_in)
    parts = strings(numel(key_columns), 1);
    for key_index = 1:numel(key_columns)
        values = table_in.(char(key_columns(key_index)));
        parts(key_index) = key_columns(key_index) + "=" + ...
            string(scalar_text_local(values, row_index));
    end
    keys(row_index) = strjoin(parts, "|");
end
ignored_keys = string(item.ignored_row_keys(:));
keep = ~ismember(keys, ignored_keys);
if numel(key_columns) == 1
    raw_keys = string(table_in.(char(key_columns(1))));
    keep = keep & ~ismember(raw_keys, ignored_keys);
end
table_out = table_in(keep, :);
keys = keys(keep);
duplicate = numel(unique(keys)) ~= numel(keys);
[keys, order] = sort(keys);
table_out = table_out(order, :);
end

function [pass, absolute_difference, relative_difference] = ...
    numeric_compare_local(old_value, new_value, absolute_tolerance, ...
    relative_tolerance)
if isnan(old_value) && isnan(new_value)
    absolute_difference = 0;
    relative_difference = 0;
    pass = true;
elseif ~isfinite(old_value) || ~isfinite(new_value)
    absolute_difference = Inf;
    relative_difference = Inf;
    pass = isequal(old_value, new_value);
else
    absolute_difference = abs(new_value - old_value);
    relative_difference = absolute_difference / ...
        max([abs(old_value), abs(new_value), realmin]);
    pass = absolute_difference <= absolute_tolerance || ...
        relative_difference <= relative_tolerance;
end
end

function row = row_local(item, row_key, column_name, kind, old_text, ...
    new_text, old_numeric, new_numeric, absolute_difference, ...
    relative_difference, absolute_tolerance, relative_tolerance, ...
    expected_identity_change_flag, pass_flag)
row = struct('artifact_id', item.artifact_id, ...
    'relative_path', item.relative_path, 'row_key', string(row_key), ...
    'column_name', string(column_name), 'comparison_kind', string(kind), ...
    'old_value_text', string(old_text), 'new_value_text', string(new_text), ...
    'old_numeric_value', old_numeric, 'new_numeric_value', new_numeric, ...
    'absolute_difference', absolute_difference, ...
    'relative_difference', relative_difference, ...
    'absolute_tolerance', absolute_tolerance, ...
    'relative_tolerance', relative_tolerance, ...
    'expected_identity_change_flag', logical(expected_identity_change_flag), ...
    'pass_flag', logical(pass_flag));
end

function table_out = rows_to_table_local(rows)
if isempty(rows)
    table_out = table('Size', [0, 15], 'VariableTypes', { ...
        'string','string','string','string','string','string','string', ...
        'double','double','double','double','double','double','logical','logical'}, ...
        'VariableNames', {'artifact_id','relative_path','row_key', ...
        'column_name','comparison_kind','old_value_text','new_value_text', ...
        'old_numeric_value','new_numeric_value','absolute_difference', ...
        'relative_difference','absolute_tolerance','relative_tolerance', ...
        'expected_identity_change_flag','pass_flag'});
else
    table_out = struct2table(vertcat(rows{:}));
end
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
elseif iscategorical(value)
    text = char(string(value));
else
    text = char(string(value));
end
end

function text = value_text_local(value)
if islogical(value)
    text = char(string(double(value)));
else
    text = char(string(value));
end
end

function value = max_finite_local(current, candidate)
if isfinite(candidate)
    value = max(current, candidate);
elseif isinf(candidate)
    value = Inf;
else
    value = current;
end
end
