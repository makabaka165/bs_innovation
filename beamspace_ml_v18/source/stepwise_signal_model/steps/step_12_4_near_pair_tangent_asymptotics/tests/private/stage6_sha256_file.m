function digest = stage6_sha256_file(path_now)
%STAGE6_SHA256_FILE Hash the raw bytes of one file in bounded chunks.

if isstring(path_now), path_now = char(path_now); end
if ~(ischar(path_now) && isrow(path_now) && exist(path_now, 'file') == 2)
    error('stage6_sha256_file:MissingFile', ...
        'path_now must identify an existing file.');
end
fid = fopen(path_now, 'rb');
if fid < 0
    error('stage6_sha256_file:Open', 'Unable to open %s.', path_now);
end
cleanup = onCleanup(@() fclose(fid));
md = java.security.MessageDigest.getInstance('SHA-256');
while true
    block = fread(fid, 1024 * 1024, '*uint8');
    if isempty(block), break; end
    md.update(block);
end
bytes = typecast(md.digest(), 'uint8');
digest = lower(reshape(dec2hex(bytes, 2).', 1, []));
end
