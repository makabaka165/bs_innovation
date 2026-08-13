function digest = stage8_k2_snr_stable_hash(varargin)
%STAGE8_K2_SNR_STABLE_HASH Namespace the canonical Stage8 hash routine.

digest = stage8_stable_hash( ...
    'STAGE8_K2_SNR_DOMAIN_VALIDATION_V1', varargin{:});
end
