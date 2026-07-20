function result = verify_stage8_1a5_real_mean_cases( ...
    fixture, measurement_config_id, noise_profile_id)
%VERIFY_STAGE8_1A5_REAL_MEAN_CASES Check center and off-center real fits.

config = string(measurement_config_id);
noise = string(noise_profile_id);
matches = arrayfun(@(item) ...
    string(item.cell_input.measurement_config_id) == config && ...
    string(item.cell_input.noise_profile_id) == noise, fixture.cases);
cases = fixture.cases(matches);
assert(numel(cases) == 2, 'verify_stage8_1a5_real_mean_cases:Cardinality', ...
    'Each real config/noise regression must contain exactly two centers.');

pass_flag = false(2, 1);
global_cell_index = zeros(2, 1);
center_az_deg = zeros(2, 1);
center_el_deg = zeros(2, 1);
G_max_bound_ratio = zeros(2, 1);
mean_max_bound_ratio = zeros(2, 1);
old_relative_mean_error = zeros(2, 1);
for index = 1:2
    cell_input = cases(index).cell_input;
    model = cases(index).model;
    evaluation = cases(index).evaluation;
    real_model = ~isequal(model.W_I, eye(size(model.W_I)));
    pass_flag(index) = cell_input.L == 1 && cell_input.snr_db == -12 && ...
        real_model && evaluation.overall_pass && ...
        evaluation.G_identity_pass && evaluation.mean_identity_pass && ...
        strcmp(evaluation.failure_status, 'BOOTSTRAP_MEAN_IDENTITY_PASS');
    global_cell_index(index) = cell_input.global_cell_index;
    center_az_deg(index) = cell_input.center_az_deg;
    center_el_deg(index) = cell_input.center_el_deg;
    G_max_bound_ratio(index) = evaluation.G_max_bound_ratio;
    mean_max_bound_ratio(index) = evaluation.mean_max_bound_ratio;
    old_relative_mean_error(index) = ...
        evaluation.mean_old_relative_residual;
end
centers = sortrows([center_az_deg, center_el_deg], [1, 2]);
pass_flag(:) = pass_flag & isequal(centers, [7.6,9.8;8,10]);
assert(all(pass_flag), 'verify_stage8_1a5_real_mean_cases:Failed', ...
    'A registered real mean-identity regression failed.');
result = table(pass_flag, global_cell_index, center_az_deg, center_el_deg, ...
    G_max_bound_ratio, mean_max_bound_ratio, old_relative_mean_error, ...
    'VariableNames', {'pass_flag','global_cell_index','center_az_deg', ...
    'center_el_deg','G_max_bound_ratio','mean_max_bound_ratio', ...
    'old_relative_mean_error'});
end
