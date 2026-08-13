function stage8_r1_write_json_atomic(path_now, value)
%STAGE8_R1_WRITE_JSON_ATOMIC Write one UTF-8 JSON file by atomic rename.

path_now = char(string(path_now));
parent = fileparts(path_now);
if ~isfolder(parent), mkdir(parent); end
temporary = [path_now, '.tmp'];
fid = fopen(temporary, 'w', 'n', 'UTF-8');
if fid < 0
    error('stage8_r1_write_json_atomic:Open', ...
        'Unable to open temporary JSON file: %s.', temporary);
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, jsonencode(value, 'PrettyPrint', true), 'char');
fwrite(fid, newline, 'char');
clear cleanup
[moved, message] = movefile(temporary, path_now, 'f');
if ~moved
    error('stage8_r1_write_json_atomic:Move', '%s', message);
end
end
