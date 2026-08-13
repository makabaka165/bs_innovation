function digest = stage8_k2_mc_stable_hash(varargin)
%STAGE8_K2_MC_STABLE_HASH Namespace the canonical Stage8 hash routine.

digest = stage8_stable_hash('STAGE8_K2_WHITE_SNR_MONTE_CARLO_V1', ...
    varargin{:});
end
