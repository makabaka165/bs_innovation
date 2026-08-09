function [digest, payload_bytes] = stage8_k2_tecs_sha256(domain, value, serialized)
%STAGE8_K2_TECS_SHA256 Domain-separated SHA-256 over canonical bytes.

if nargin < 3, serialized = false; end
if ~(ischar(domain) || (isstring(domain) && isscalar(domain)))
    error('stage8_k2_tecs_sha256:Domain', ...
        'domain must be a char vector or scalar string.');
end
domain_bytes = unicode2native(char(string(domain)), 'UTF-8');
if serialized
    if ~isa(value, 'uint8') || ~isvector(value)
        error('stage8_k2_tecs_sha256:SerializedBytes', ...
            'A serialized payload must be a uint8 vector.');
    end
    payload_bytes = reshape(value, 1, []);
else
    payload_bytes = stage8_k2_tecs_serialize(value);
end
prefix = unicode2native('STAGE8_K2_TECS_SHA256_V1', 'UTF-8');
material = [frame_local(prefix), frame_local(domain_bytes), ...
    frame_local(payload_bytes)];
raw = java.security.MessageDigest.getInstance('SHA-256').digest( ...
    typecast(material, 'int8'));
unsigned = mod(double(raw), 256);
digest = lower(reshape(dec2hex(unsigned, 2).', 1, []));
end

function output = frame_local(bytes)
bytes = reshape(uint8(bytes), 1, []);
output = [typecast(uint64(numel(bytes)), 'uint8'), bytes];
end
