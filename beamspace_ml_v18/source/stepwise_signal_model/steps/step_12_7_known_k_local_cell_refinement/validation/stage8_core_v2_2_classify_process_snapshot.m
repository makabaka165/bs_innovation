function audit = stage8_core_v2_2_classify_process_snapshot( ...
    snapshot, current_matlab_pid)
%STAGE8_CORE_V2_2_CLASSIFY_PROCESS_SNAPSHOT Classify exact process identities.

snapshot = normalize_snapshot_local(snapshot);
current_matlab_pid = double(current_matlab_pid);
if ~isscalar(current_matlab_pid) || ~isfinite(current_matlab_pid) || ...
        current_matlab_pid <= 0 || current_matlab_pid ~= fix(current_matlab_pid)
    error('stage8_core_v2_2_classify_process_snapshot:CurrentPid', ...
        'current_matlab_pid must be a positive integer scalar.');
end
if ~any(snapshot.process_id == current_matlab_pid)
    error('stage8_core_v2_2_classify_process_snapshot:CurrentPidMissing', ...
        'The current MATLAB process is absent from the snapshot.');
end

lineage = current_matlab_pid;
cursor = current_matlab_pid;
for step = 1:height(snapshot)
    row = find(snapshot.process_id == cursor, 1);
    if isempty(row), break; end
    parent = snapshot.parent_process_id(row);
    if parent <= 0 || ~any(snapshot.process_id == parent) || ...
            any(lineage == parent)
        break;
    end
    lineage(end + 1) = parent; %#ok<AGROW>
    cursor = parent;
end

normalized_name = lower(strtrim(snapshot.name));
outside_lineage = ~ismember(snapshot.process_id, lineage);
external_matlab_mask = outside_lineage & ...
    ismember(normalized_name, ["matlab.exe", "matlab"]);
mwpython_mask = outside_lineage & ...
    ismember(normalized_name, ["mwpython.exe", "mwpython"]);

shell_names = ["powershell.exe", "powershell", "pwsh.exe", "pwsh", ...
    "cmd.exe", "cmd"];
legacy_basenames = ["Stage8K1Sharded.ps1", ...
    "Stage8CompactDiagnostic.ps1", "Stage8R1Decisive.ps1", ...
    "Stage8CoreV2.ps1"];
legacy_mask = false(height(snapshot), 1);
matched_basename = strings(height(snapshot), 1);
for row = 1:height(snapshot)
    if ~ismember(normalized_name(row), shell_names)
        continue;
    end
    for candidate = legacy_basenames
        if contains_exact_basename_local( ...
                snapshot.command_line(row), candidate)
            legacy_mask(row) = true;
            matched_basename(row) = candidate;
            break;
        end
    end
end

external_matches = snapshot(external_matlab_mask, :);
mwpython_matches = snapshot(mwpython_mask, :);
legacy_matches = snapshot(legacy_mask, :);
legacy_matches.matched_basename = matched_basename(legacy_mask);
audit = struct( ...
    'process_snapshot_count', height(snapshot), ...
    'current_lineage_ids', lineage, ...
    'external_matlab_count', height(external_matches), ...
    'external_matlab_matches', external_matches, ...
    'mwpython_count', height(mwpython_matches), ...
    'mwpython_matches', mwpython_matches, ...
    'legacy_orchestrator_count', height(legacy_matches), ...
    'legacy_orchestrator_matches', legacy_matches, ...
    'coordinator_count', height(legacy_matches), ...
    'coordinator_count_semantics', ...
    'EXACT_KNOWN_LEGACY_ORCHESTRATOR_COUNT', ...
    'process_audit_method', 'STRUCTURED_SNAPSHOT_EXACT_IDENTITY_V1');
end

function snapshot = normalize_snapshot_local(snapshot)
if isstruct(snapshot)
    snapshot = struct2table(snapshot);
end
if ~istable(snapshot)
    error('stage8_core_v2_2_classify_process_snapshot:SnapshotType', ...
        'snapshot must be a table or struct array.');
end
required = {'process_id', 'parent_process_id', 'name', ...
    'executable_path', 'command_line'};
if ~all(ismember(required, snapshot.Properties.VariableNames))
    error('stage8_core_v2_2_classify_process_snapshot:SnapshotFields', ...
        'snapshot is missing required fields.');
end
process_id = numeric_column_local(snapshot.process_id, ...
    'process_id', true);
parent_process_id = numeric_column_local(snapshot.parent_process_id, ...
    'parent_process_id', true);
name = text_column_local(snapshot.name, 'name');
executable_path = text_column_local(snapshot.executable_path, ...
    'executable_path');
command_line = text_column_local(snapshot.command_line, 'command_line');
count = numel(process_id);
if any([numel(parent_process_id), numel(name), numel(executable_path), ...
        numel(command_line)] ~= count)
    error('stage8_core_v2_2_classify_process_snapshot:SnapshotHeight', ...
        'snapshot columns must have equal heights.');
end
[process_id, order] = sort(process_id);
if numel(unique(process_id)) ~= count
    error('stage8_core_v2_2_classify_process_snapshot:DuplicatePid', ...
        'snapshot contains duplicate process IDs.');
end
snapshot = table(process_id, parent_process_id(order), name(order), ...
    executable_path(order), command_line(order), 'VariableNames', required);
end

function values = numeric_column_local(values, field, allow_zero)
if ~isnumeric(values) || ~isvector(values)
    error('stage8_core_v2_2_classify_process_snapshot:NumericColumn', ...
        '%s must be a numeric vector.', field);
end
values = double(values(:));
minimum = double(~allow_zero);
if any(~isfinite(values) | values < minimum | values ~= fix(values))
    error('stage8_core_v2_2_classify_process_snapshot:NumericValue', ...
        '%s contains an invalid process ID.', field);
end
end

function values = text_column_local(values, field)
if ischar(values)
    values = string(cellstr(values));
elseif iscellstr(values) || isstring(values)
    values = string(values);
else
    error('stage8_core_v2_2_classify_process_snapshot:TextColumn', ...
        '%s must contain text.', field);
end
values = values(:);
values(ismissing(values)) = "";
end

function matched = contains_exact_basename_local(command_line, basename)
pattern = "(?i)(?<![A-Za-z0-9_.-])" + ...
    regexptranslate('escape', basename) + "(?![A-Za-z0-9_.-])";
matched = ~isempty(regexp(char(command_line), char(pattern), 'once'));
end
