function [bank, parameters_deg] = build_registered_candidate_bank( ...
    grid_deg, Q, model)
%BUILD_REGISTERED_CANDIDATE_BANK Build the finite local alias-test bank.

grid_deg = unique(grid_deg(:), 'sorted');
if Q == 1
    parameters_deg = grid_deg;
elseif Q == 2
    pair_index = nchoosek(1:numel(grid_deg), 2);
    parameters_deg = [grid_deg(pair_index(:, 1)), grid_deg(pair_index(:, 2))];
else
    error('build_registered_candidate_bank:GroupCount', ...
        'Only Q=1 or Q=2 is supported in this phase.');
end
bank = cell(size(parameters_deg, 1), 1);
for idx = 1:numel(bank)
    [bank{idx}, ~] = build_elevation_group_manifold( ...
        parameters_deg(idx, :), model, struct());
end
end
