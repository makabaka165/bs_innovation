function digest = stage8_k2_snr_file_sha256(path_now)
%STAGE8_K2_SNR_FILE_SHA256 Hash one file without text normalization.

fid = fopen(path_now, 'rb');
if fid < 0
    error('stage8_k2_snr_file_sha256:Open', ...
        'Unable to open file for hashing: %s', path_now);
end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');
sha = System.Security.Cryptography.SHA256.Create();
sha_cleanup = onCleanup(@() sha.Dispose());
hashed = uint8(sha.ComputeHash(bytes));
digest = lower(reshape(dec2hex(hashed, 2).', 1, []));
clear sha_cleanup cleanup
end
