function stage8_k2_wacb_write_text_atomic(path_now, content)
%STAGE8_K2_WACB_WRITE_TEXT_ATOMIC Replace one UTF-8 text file atomically.

temporary = [char(string(path_now)), '.tmp'];
fid = fopen(temporary, 'w', 'n', 'UTF-8');
if fid < 0
    error('stage8_k2_wacb_write_text_atomic:Open', ...
        'Unable to open temporary file: %s', temporary);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', char(string(content)));
clear cleanup
[ok, message] = movefile(temporary, path_now, 'f');
if ~ok
    error('stage8_k2_wacb_write_text_atomic:Move', '%s', message);
end
end
