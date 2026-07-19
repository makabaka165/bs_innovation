function result = test_group_noise_invalid_makes_start_unavailable()
%TEST_GROUP_NOISE_INVALID_MAKES_START_UNAVAILABLE Check invalid-scale state.

values = [NaN,0,-1,Inf];
available = false(size(values));
status = strings(size(values));
for index = 1:numel(values)
    contract = validate_stage8_group_noise_scale(values(index));
    available(index) = contract.start_available_flag;
    status(index) = string(contract.status);
end
pass = ~any(available) && all(status == "GROUP_NOISE_SCALE_INVALID");
assert(pass, 'test_group_noise_invalid_makes_start_unavailable:Failed', ...
    'An invalid group-noise scale left a grouped start available.');
result = table(pass, 'VariableNames', {'pass_flag'});
end
