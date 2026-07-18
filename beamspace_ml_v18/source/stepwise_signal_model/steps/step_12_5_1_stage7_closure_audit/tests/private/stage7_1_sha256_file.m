function digest = stage7_1_sha256_file(path_now)
%STAGE7_1_SHA256_FILE Return the binary SHA-256 of one file.

fid = fopen(path_now, 'rb');
if fid < 0
    error('stage7_1_sha256_file:Open', 'Unable to open %s.', path_now);
end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');
sha = System.Security.Cryptography.SHA256.Create();
sha_cleanup = onCleanup(@() sha.Dispose());
digest_bytes = uint8(sha.ComputeHash(bytes));
digest = lower(reshape(dec2hex(digest_bytes, 2).', 1, []));
clear sha_cleanup cleanup
end
