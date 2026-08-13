function stage8_k2_mc_write_text_atomic(path_now, text_now)
%STAGE8_K2_MC_WRITE_TEXT_ATOMIC Replace one text file atomically.

folder = fileparts(path_now);
if ~isfolder(folder) && ~mkdir(folder)
    error('stage8_k2_mc_write_text_atomic:Directory', ...
        'Unable to create directory: %s', folder);
end
temporary = [path_now, '.tmp'];
if isfile(temporary)
    delete(temporary);
end
fid = fopen(temporary, 'w');
if fid < 0
    error('stage8_k2_mc_write_text_atomic:Open', ...
        'Unable to open temporary text file: %s', temporary);
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, char(text_now), 'char');
clear cleanup
[ok, message] = movefile(temporary, path_now, 'f');
if ~ok
    error('stage8_k2_mc_write_text_atomic:Move', '%s', message);
end
end
