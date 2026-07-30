function digest = stage8_k2_cb_stable_hash(varargin)
%STAGE8_K2_CB_STABLE_HASH Namespace the frozen canonical hash routine.

digest = stage8_stable_hash( ...
    'STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_V1', varargin{:});
end
