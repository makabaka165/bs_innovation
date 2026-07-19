function digest = stage8_sha256_file(path_now)
%STAGE8_SHA256_FILE Return the SHA-256 hash of raw file bytes.

stream = System.IO.File.OpenRead(path_now);
stream_cleanup = onCleanup(@() stream.Dispose());
sha = System.Security.Cryptography.SHA256.Create();
sha_cleanup = onCleanup(@() sha.Dispose());
bytes = uint8(sha.ComputeHash(stream));
digest = lower(reshape(dec2hex(bytes, 2).', 1, []));
clear sha_cleanup stream_cleanup
end
