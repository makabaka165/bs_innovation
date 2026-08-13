function digest = stage8_k2_wcb_stable_hash(varargin)
%STAGE8_K2_WCB_STABLE_HASH Namespace the canonical Stage8 hash routine.

digest = stage8_stable_hash( ...
    'STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_FINAL_COMPARISON_V1', ...
    varargin{:});
end
