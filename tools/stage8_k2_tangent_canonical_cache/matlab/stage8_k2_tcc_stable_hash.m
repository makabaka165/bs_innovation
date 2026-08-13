function digest = stage8_k2_tcc_stable_hash(varargin)
%STAGE8_K2_TCC_STABLE_HASH Namespace the repository SHA-256 routine.

digest = stage8_stable_hash('STAGE8_K2_TANGENT_CANONICAL_CACHE_LEVEL_A_V1', ...
    varargin{:});
end
