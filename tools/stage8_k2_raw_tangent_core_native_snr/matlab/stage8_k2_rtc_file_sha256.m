function digest = stage8_k2_rtc_file_sha256(filename)
fid = fopen(filename,'rb');
assert(fid>=0,'RTC:HashOpen','Unable to hash %s.',filename);
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid,Inf,'*uint8');
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(typecast(bytes,'int8'));
digest = lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
