function snapshot = stage8_core_v2_2_process_snapshot()
%STAGE8_CORE_V2_2_PROCESS_SNAPSHOT Capture one structured process table.

command = ['powershell -NoProfile -NonInteractive -Command "' ...
    '$rows = @(Get-CimInstance Win32_Process | Select-Object ' ...
    'ProcessId,ParentProcessId,Name,ExecutablePath,CommandLine); ' ...
    '$rows | ConvertTo-Json -Compress -Depth 3"'];
[status, output] = system(command);
if status ~= 0
    error('stage8_core_v2_2_process_snapshot:Query', ...
        'The Windows process snapshot query failed.');
end
payload = strtrim(output);
if isempty(payload)
    error('stage8_core_v2_2_process_snapshot:Empty', ...
        'The Windows process snapshot query returned no JSON.');
end
try
    rows = jsondecode(payload);
catch exception
    error('stage8_core_v2_2_process_snapshot:Json', ...
        'Unable to parse the Windows process snapshot: %s', ...
        exception.message);
end
if ~isstruct(rows) || isempty(rows)
    error('stage8_core_v2_2_process_snapshot:Rows', ...
        'The Windows process snapshot must contain structured rows.');
end

required = {'ProcessId', 'ParentProcessId', 'Name', ...
    'ExecutablePath', 'CommandLine'};
if ~all(isfield(rows, required))
    error('stage8_core_v2_2_process_snapshot:Fields', ...
        'The Windows process snapshot is missing required fields.');
end
count = numel(rows);
process_id = zeros(count, 1);
parent_process_id = zeros(count, 1);
name = strings(count, 1);
executable_path = strings(count, 1);
command_line = strings(count, 1);
for index = 1:count
    process_id(index) = numeric_id_local(rows(index).ProcessId, ...
        'ProcessId', true);
    parent_process_id(index) = numeric_id_local( ...
        rows(index).ParentProcessId, 'ParentProcessId', true);
    name(index) = text_local(rows(index).Name, 'Name');
    executable_path(index) = text_local( ...
        rows(index).ExecutablePath, 'ExecutablePath');
    command_line(index) = text_local(rows(index).CommandLine, ...
        'CommandLine');
end
[process_id, order] = sort(process_id);
parent_process_id = parent_process_id(order);
name = name(order);
executable_path = executable_path(order);
command_line = command_line(order);
if numel(unique(process_id)) ~= count
    error('stage8_core_v2_2_process_snapshot:DuplicatePid', ...
        'The Windows process snapshot contains duplicate process IDs.');
end
snapshot = table(process_id, parent_process_id, name, executable_path, ...
    command_line);
end

function value = numeric_id_local(raw, field, allow_zero)
if ~isnumeric(raw) || ~isscalar(raw)
    error('stage8_core_v2_2_process_snapshot:NumericField', ...
        '%s must be a numeric scalar.', field);
end
value = double(raw);
minimum = double(~allow_zero);
if ~isfinite(value) || value < minimum || value ~= fix(value)
    error('stage8_core_v2_2_process_snapshot:NumericValue', ...
        '%s must be a finite integer in its valid range.', field);
end
end

function value = text_local(raw, field)
if isempty(raw)
    value = "";
elseif ischar(raw) || (isstring(raw) && isscalar(raw))
    value = string(raw);
else
    error('stage8_core_v2_2_process_snapshot:TextField', ...
        '%s must be text or JSON null.', field);
end
if ismissing(value)
    value = "";
end
end
