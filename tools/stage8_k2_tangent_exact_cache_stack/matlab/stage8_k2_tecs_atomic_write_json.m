function stage8_k2_tecs_atomic_write_json(path_now, value)
%STAGE8_K2_TECS_ATOMIC_WRITE_JSON Write UTF-8 JSON by same-volume rename.

temporary = [path_now, '.tmp'];
if isfile(temporary), delete(temporary); end
fid = fopen(temporary, 'wb');
if fid < 0
    error('stage8_k2_tecs_atomic_write_json:Open', ...
        'Unable to open %s.', temporary);
end
cleanup = onCleanup(@() fclose(fid));
bytes = unicode2native([jsonencode(value, 'PrettyPrint', true), newline], ...
    'UTF-8');
fwrite(fid, bytes, 'uint8');
clear cleanup
[moved, message] = movefile(temporary, path_now, 'f');
if ~moved
    error('stage8_k2_tecs_atomic_write_json:Rename', '%s', message);
end
end
