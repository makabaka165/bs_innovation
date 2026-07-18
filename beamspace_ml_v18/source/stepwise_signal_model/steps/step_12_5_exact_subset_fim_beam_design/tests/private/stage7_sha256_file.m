function digest = stage7_sha256_file(path_now)
%STAGE7_SHA256_FILE Return the SHA-256 digest of one file.

fid = fopen(path_now, 'rb');
if fid < 0
    error('stage7_sha256_file:Open', 'Unable to open %s.', path_now);
end
file_cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');
sha = System.Security.Cryptography.SHA256.Create();
sha_cleanup = onCleanup(@() sha.Dispose());
digest_bytes = uint8(sha.ComputeHash(bytes));
digest = lower(reshape(dec2hex(digest_bytes, 2).', 1, []));
clear sha_cleanup file_cleanup
end
