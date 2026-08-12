function result = test_stage8_k2_mc_negative_unshifted_beam(~, outputs)
%TEST_STAGE8_K2_MC_NEGATIVE_UNSHIFTED_BEAM Check fail-closed rejection.
row = outputs.static.negative_controls( ...
    outputs.static.negative_controls.control_id == "UNSHIFTED_BEAM",:);
pass = height(row) == 1 && row.admission_rejected && row.pass && ...
    row.admission_error_id == "stage8_k2_mc_validate_rotation_class:DeclaredIdentity";
assert(pass, 'test_stage8_k2_mc_negative_unshifted_beam:Failed');
result = struct('pass',pass,'metric',row.metric);
end
