function digest = stage8_k2_rtc_hash(varargin)
md = java.security.MessageDigest.getInstance('SHA-256');
for k = 1:nargin
    bytes = getByteStreamFromArray(varargin{k});
    md.update(typecast(uint64(numel(bytes)), 'int8'));
    md.update(typecast(bytes, 'int8'));
end
digest = lower(reshape(dec2hex(typecast(md.digest(), 'uint8'), 2).', 1, []));
end
