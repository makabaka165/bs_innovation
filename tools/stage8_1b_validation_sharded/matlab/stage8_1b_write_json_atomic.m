function stage8_1b_write_json_atomic(path_now, value)
%STAGE8_1B_WRITE_JSON_ATOMIC Replace a mutable runtime JSON atomically.

path_now = char(string(path_now));
parent = fileparts(path_now);
if ~isfolder(parent), mkdir(parent); end
temporary = [path_now, '.tmp'];
fid = fopen(temporary, 'w', 'n', 'UTF-8');
if fid < 0
    error('stage8_1b_write_json_atomic:Open', ...
        'Unable to open temporary JSON: %s.', temporary);
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, jsonencode(value), 'char');
fwrite(fid, newline, 'char');
clear cleanup
if ~movefile(temporary, path_now, 'f')
    error('stage8_1b_write_json_atomic:Move', ...
        'Unable to publish JSON: %s.', path_now);
end
end
