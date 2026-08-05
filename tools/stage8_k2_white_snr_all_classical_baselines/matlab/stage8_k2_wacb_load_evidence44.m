function evidence = stage8_k2_wacb_load_evidence44(repo_dir, constants)
%STAGE8_K2_WACB_LOAD_EVIDENCE44 Verify and reuse immutable evidence 44.

if nargin < 2 || isempty(constants) %#ok<INUSD>
    constants = stage8_k2_wacb_constants(); %#ok<NASGU>
end
% The frozen V1 loader owns the evidence-44 three-method schema.
evidence = stage8_k2_wcb_load_evidence44( ...
    repo_dir, stage8_k2_wcb_constants());
end
