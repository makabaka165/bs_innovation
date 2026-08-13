function applicability = stage8_k2_sb_applicability(spec, method_id)
%STAGE8_K2_SB_APPLICABILITY Apply structural N/A rules before fitting.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_k2_sb_applicability:Spec', ...
        'spec must be one registered trial row.');
end
method_id = string(method_id);
constants = stage8_k2_sb_constants();
if ~ismember(method_id, constants.method_ids)
    error('stage8_k2_sb_applicability:Method', ...
        'Unknown structured-subspace method ID.');
end
applicability = struct('applicable', true, 'status', "APPLICABLE");
if spec.profile_id == "P2"
    applicability.applicable = false;
    applicability.status = ...
        "NOT_APPLICABLE_EQUAL_ELEVATION_MULTIPLICITY";
elseif method_id == "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML" && ...
        spec.noise_profile_id ~= "WHITE"
    applicability.applicable = false;
    applicability.status = ...
        "NOT_APPLICABLE_COLORED_NOISE_STANDARD_ROOT_MUSIC";
elseif method_id == "ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML" && ...
        spec.noise_profile_id ~= "WHITE"
    applicability.applicable = false;
    applicability.status = ...
        "NOT_APPLICABLE_COLORED_NOISE_STANDARD_ESPRIT";
end
end
