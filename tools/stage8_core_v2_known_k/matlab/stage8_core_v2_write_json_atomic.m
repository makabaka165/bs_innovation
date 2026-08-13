function stage8_core_v2_write_json_atomic(path_now, value)
%STAGE8_CORE_V2_WRITE_JSON_ATOMIC Write UTF-8 JSON through a temporary file.

parent = fileparts(char(string(path_now)));
if ~isfolder(parent), mkdir(parent); end
temporary = [char(string(path_now)), '.tmp'];
fid = fopen(temporary, 'w', 'n', 'UTF-8');
if fid < 0
    error('stage8_core_v2_write_json_atomic:Open', ...
        'Cannot open temporary JSON file.');
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, [jsonencode(value), newline], 'char');
clear cleanup
[moved, message] = movefile(temporary, char(string(path_now)), 'f');
if ~moved
    error('stage8_core_v2_write_json_atomic:Move', '%s', message);
end
end
