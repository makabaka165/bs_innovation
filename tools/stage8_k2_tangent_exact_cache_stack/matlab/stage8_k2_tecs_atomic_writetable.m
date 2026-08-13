function stage8_k2_tecs_atomic_writetable(value, path_now)
%STAGE8_K2_TECS_ATOMIC_WRITETABLE Write a CSV by same-volume rename.

temporary = [path_now, '.tmp.csv'];
if isfile(temporary), delete(temporary); end
writetable(value, temporary);
[moved, message] = movefile(temporary, path_now, 'f');
if ~moved
    error('stage8_k2_tecs_atomic_writetable:Rename', '%s', message);
end
end
