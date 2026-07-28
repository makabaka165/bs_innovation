function total_sec = stage8_1b_active_wall_seconds(runtime_root)
%STAGE8_1B_ACTIVE_WALL_SECONDS Union completed worker-attempt intervals.

runtime_root = char(string(runtime_root));
files = dir(fullfile(runtime_root, 'workers', 'attempt_*.json'));
starts = zeros(0, 1);
ends = zeros(0, 1);
for index = 1:numel(files)
    value = jsondecode(fileread(fullfile(files(index).folder, files(index).name)));
    if ~isfield(value, 'started_utc') || ~isfield(value, 'ended_utc') || ...
            isempty(value.started_utc) || isempty(value.ended_utc)
        continue;
    end
    start_now = parse_utc_local(value.started_utc);
    end_now = parse_utc_local(value.ended_utc);
    if ~(isfinite(start_now) && isfinite(end_now) && end_now >= start_now)
        error('stage8_1b_active_wall_seconds:AttemptInterval', ...
            'Worker attempt has an invalid active interval: %s.', ...
            files(index).name);
    end
    starts(end + 1, 1) = start_now; %#ok<AGROW>
    ends(end + 1, 1) = end_now; %#ok<AGROW>
end
if isempty(starts)
    error('stage8_1b_active_wall_seconds:NoIntervals', ...
        'No completed worker attempt intervals are available.');
end
[starts, order] = sort(starts);
ends = ends(order);
current_start = starts(1);
current_end = ends(1);
total_sec = 0;
for index = 2:numel(starts)
    if starts(index) <= current_end
        current_end = max(current_end, ends(index));
    else
        total_sec = total_sec + current_end - current_start;
        current_start = starts(index);
        current_end = ends(index);
    end
end
total_sec = double(total_sec + current_end - current_start);
end

function value = parse_utc_local(text_value)
parsed = datetime(char(string(text_value)), 'TimeZone', 'UTC', ...
    'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''');
value = posixtime(parsed);
end
