function rule = stage8_k2_wacb_applicability(spec, method_id)
%STAGE8_K2_WACB_APPLICABILITY Apply only registered structural N/A rules.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_k2_wacb_applicability:Spec', ...
        'spec must be one registered trial row.');
end
constants = stage8_k2_wacb_constants();
method_id = string(method_id);
if ~ismember(method_id, constants.method_ids)
    error('stage8_k2_wacb_applicability:Method', 'Unknown new method ID.');
end
rule = struct('applicable', true, 'status', "APPLICABLE", ...
    'uses_registered_scenario_flag', false);
if method_id == "ELEMENT_MUSIC_K2" && double(spec.L) == 1
    rule.applicable = false;
    rule.status = "NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK";
elseif method_id ~= "ELEMENT_MUSIC_K2" && spec.profile_id == "P2"
    rule.applicable = false;
    rule.status = "NOT_APPLICABLE_EQUAL_ELEVATION_MULTIPLICITY";
    rule.uses_registered_scenario_flag = true;
elseif method_id == "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML" && ...
        spec.noise_profile_id ~= "WHITE"
    rule.applicable = false;
    rule.status = "NOT_APPLICABLE_COLORED_NOISE_STANDARD_ROOT_MUSIC";
    rule.uses_registered_scenario_flag = true;
elseif method_id == "ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML" && ...
        spec.noise_profile_id ~= "WHITE"
    rule.applicable = false;
    rule.status = "NOT_APPLICABLE_COLORED_NOISE_STANDARD_ESPRIT";
    rule.uses_registered_scenario_flag = true;
end
end
