function result = test_stage8_k2_mc_negative_wrong_center(~, outputs)
%TEST_STAGE8_K2_MC_NEGATIVE_WRONG_CENTER Check actual-center rejection.
row = outputs.static.negative_controls( ...
    outputs.static.negative_controls.control_id == "REQUESTED_CENTER_AS_PHYSICAL",:);
pass = height(row) == 1 && row.admission_rejected && row.pass && ...
    row.admission_error_id == "stage8_k2_mc_validate_rotation_class:PhysicalCenter";
assert(pass, 'test_stage8_k2_mc_negative_wrong_center:Failed');
result = struct('pass',pass,'metric',row.metric);
end
