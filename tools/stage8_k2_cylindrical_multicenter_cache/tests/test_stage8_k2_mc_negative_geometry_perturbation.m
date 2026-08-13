function result = test_stage8_k2_mc_negative_geometry_perturbation(~, outputs)
%TEST_STAGE8_K2_MC_NEGATIVE_GEOMETRY_PERTURBATION Check geometry rejection.
row = outputs.static.negative_controls( ...
    outputs.static.negative_controls.control_id == "GEOMETRY_PERTURBATION",:);
pass = height(row) == 1 && row.admission_rejected && row.pass && ...
    row.metric > 1e-9;
assert(pass, 'test_stage8_k2_mc_negative_geometry_perturbation:Failed');
result = struct('pass',pass,'metric',row.metric);
end
