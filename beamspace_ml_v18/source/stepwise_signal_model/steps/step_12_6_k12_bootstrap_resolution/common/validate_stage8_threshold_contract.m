function contract = validate_stage8_threshold_contract(contract)
%VALIDATE_STAGE8_THRESHOLD_CONTRACT Validate exact provenance identities.

required = {'stage8_stable_code_identity_hash','stage8_plan_hash', ...
    'stage8_calibration_plan_hash','measurement_registry_hash'};
forbidden_tokens = ["truth";"scene";"separation"; ...
    "score" + "_" + "gap";"scoregap"];
if ~(isstruct(contract) && isscalar(contract) && all(isfield(contract, required)))
    error('validate_stage8_threshold_contract:Incomplete', ...
        'The expected threshold contract is incomplete.');
end
names = lower(string(fieldnames(contract)));
for token_index = 1:numel(forbidden_tokens)
    if any(contains(names, forbidden_tokens(token_index)))
        error('validate_stage8_threshold_contract:ForbiddenInput', ...
            'Threshold provenance cannot depend on truth, scene, separation, or score gap.');
    end
end
for field_index = 1:numel(required)
    value = string(contract.(required{field_index}));
    if ~isscalar(value) || ismissing(value) || strlength(value) == 0
        error('validate_stage8_threshold_contract:Identity', ...
            'Threshold provenance identities must be nonempty scalar text.');
    end
    contract.(required{field_index}) = char(value);
end
end
