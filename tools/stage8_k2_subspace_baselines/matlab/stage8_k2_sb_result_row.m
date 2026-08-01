function row = stage8_k2_sb_result_row(spec, trial, result, constants)
%STAGE8_K2_SB_RESULT_ROW Add truth metrics only after the complete fit.

if nargin < 4 || isempty(constants)
    constants = stage8_k2_sb_constants();
end
row = stage8_k2_cb_result_row(spec, trial, result, ...
    'FORMAL_SUBSPACE_BASELINE_RUN', NaN, constants);
end
