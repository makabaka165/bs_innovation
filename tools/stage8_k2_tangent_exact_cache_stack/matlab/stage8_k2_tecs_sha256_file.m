function digest = stage8_k2_tecs_sha256_file(path_now)
%STAGE8_K2_TECS_SHA256_FILE Stream a file into SHA-256.

fid = fopen(path_now, 'rb');
if fid < 0
    error('stage8_k2_tecs_sha256_file:Open', ...
        'Unable to open %s.', path_now);
end
cleanup = onCleanup(@() fclose(fid));
hasher = java.security.MessageDigest.getInstance('SHA-256');
while true
    bytes = fread(fid, 1048576, '*uint8');
    if isempty(bytes), break; end
    hasher.update(typecast(bytes, 'int8'));
end
raw = hasher.digest();
clear cleanup
digest = lower(reshape(dec2hex(mod(double(raw), 256), 2).', 1, []));
end
