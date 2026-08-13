function digest = stage8_k2_tecs_evidence_hash(domain, value)
%STAGE8_K2_TECS_EVIDENCE_HASH Hash evidence that may contain N/A numerics.

% Cache keys continue to use stage8_k2_tecs_sha256, whose serializer
% rejects NaN and Inf. Evidence tables use NaN/Inf only as canonical
% non-applicable numeric values and therefore require the repository's
% stable type-preserving encoder under a separate TECS domain.
digest = stage8_k2_tcc_stable_hash( ...
    'STAGE8_K2_TECS_EVIDENCE_HASH_V1', char(string(domain)), value);
end
