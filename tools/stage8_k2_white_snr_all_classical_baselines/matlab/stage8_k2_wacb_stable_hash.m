function digest = stage8_k2_wacb_stable_hash(varargin)
%STAGE8_K2_WACB_STABLE_HASH Namespace the canonical Stage8 hash routine.

digest = stage8_stable_hash( ...
    'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_V2', ...
    varargin{:});
end
