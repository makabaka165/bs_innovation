function [result, trace] = greedy_exchange_exact_subset_design( ...
    eta0, context, opts)
%GREEDY_EXCHANGE_EXACT_SUBSET_DESIGN Run exact add/drop/pair-swap search.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'initial_elevation_mask'), opts.initial_elevation_mask = 4; end
if ~isfield(opts, 'initial_azimuth_mask'), opts.initial_azimuth_mask = 4; end
if ~isfield(opts, 'available_elevation_indices')
    opts.available_elevation_indices = 1:5;
end
if ~isfield(opts, 'available_azimuth_indices')
    opts.available_azimuth_indices = 1:5;
end
validateattributes(eta0, {'numeric'}, {'scalar','real','finite','>=',0});
elevation_mask = opts.initial_elevation_mask;
azimuth_mask = opts.initial_azimuth_mask;
maximum_elevation_mask = sum(2 .^ (opts.available_elevation_indices - 1));
maximum_azimuth_mask = sum(2 .^ (opts.available_azimuth_indices - 1));
evaluation_count = 0;
rows = cell(0, 1);
start_tic = tic;
[current, evaluation_count] = evaluate_masks_local( ...
    elevation_mask, azimuth_mask, context, evaluation_count);
rows{end + 1, 1} = trace_row_local('INITIAL', current, evaluation_count);

while current.eta_design < eta0 && ...
        (elevation_mask ~= maximum_elevation_mask || ...
        azimuth_mask ~= maximum_azimuth_mask)
    candidates = cell(0, 1);
    for index = opts.available_elevation_indices( ...
            ~bitget(elevation_mask, opts.available_elevation_indices))
        [candidate, evaluation_count] = evaluate_masks_local( ...
            bitset(elevation_mask, index), azimuth_mask, context, evaluation_count);
        candidates{end + 1, 1} = candidate; %#ok<AGROW>
    end
    for index = opts.available_azimuth_indices( ...
            ~bitget(azimuth_mask, opts.available_azimuth_indices))
        [candidate, evaluation_count] = evaluate_masks_local( ...
            elevation_mask, bitset(azimuth_mask, index), context, evaluation_count);
        candidates{end + 1, 1} = candidate; %#ok<AGROW>
    end
    current = choose_add_local(candidates);
    elevation_mask = current.elevation_mask_integer;
    azimuth_mask = current.azimuth_mask_integer;
    rows{end + 1, 1} = trace_row_local('ADD', current, evaluation_count); %#ok<AGROW>
end

changed = true;
while changed && current.eta_design >= eta0
    changed = false;
    candidates = cell(0, 1);
    for index = opts.available_elevation_indices( ...
            logical(bitget(elevation_mask, opts.available_elevation_indices)))
        candidate_mask = bitset(elevation_mask, index, 0);
        if candidate_mask > 0
            [candidate, evaluation_count] = evaluate_masks_local( ...
                candidate_mask, azimuth_mask, context, evaluation_count);
            if candidate.eta_design >= eta0
                candidates{end + 1, 1} = candidate; %#ok<AGROW>
            end
        end
    end
    for index = opts.available_azimuth_indices( ...
            logical(bitget(azimuth_mask, opts.available_azimuth_indices)))
        candidate_mask = bitset(azimuth_mask, index, 0);
        if candidate_mask > 0
            [candidate, evaluation_count] = evaluate_masks_local( ...
                elevation_mask, candidate_mask, context, evaluation_count);
            if candidate.eta_design >= eta0
                candidates{end + 1, 1} = candidate; %#ok<AGROW>
            end
        end
    end
    if ~isempty(candidates)
        candidate = choose_feasible_local(candidates);
        if candidate.MAC_total < current.MAC_total || ...
                (candidate.MAC_total == current.MAC_total && ...
                candidate.B_out < current.B_out)
            current = candidate;
            elevation_mask = current.elevation_mask_integer;
            azimuth_mask = current.azimuth_mask_integer;
            changed = true;
            rows{end + 1, 1} = trace_row_local( ...
                'DROP', current, evaluation_count); %#ok<AGROW>
        end
    end
end

improved = true;
while improved && current.eta_design >= eta0
    improved = false;
    candidates = cell(0, 1);
    selected_e = opts.available_elevation_indices( ...
        logical(bitget(elevation_mask, opts.available_elevation_indices)));
    unselected_e = opts.available_elevation_indices( ...
        ~bitget(elevation_mask, opts.available_elevation_indices));
    selected_a = opts.available_azimuth_indices( ...
        logical(bitget(azimuth_mask, opts.available_azimuth_indices)));
    unselected_a = opts.available_azimuth_indices( ...
        ~bitget(azimuth_mask, opts.available_azimuth_indices));
    for drop_index = selected_e
        for add_index = unselected_e
            candidate_mask = bitset(bitset(elevation_mask, drop_index, 0), ...
                add_index, 1);
            [candidate, evaluation_count] = evaluate_masks_local( ...
                candidate_mask, azimuth_mask, context, evaluation_count);
            if candidate.eta_design >= eta0
                candidates{end + 1, 1} = candidate; %#ok<AGROW>
            end
        end
    end
    for drop_index = selected_a
        for add_index = unselected_a
            candidate_mask = bitset(bitset(azimuth_mask, drop_index, 0), ...
                add_index, 1);
            [candidate, evaluation_count] = evaluate_masks_local( ...
                elevation_mask, candidate_mask, context, evaluation_count);
            if candidate.eta_design >= eta0
                candidates{end + 1, 1} = candidate; %#ok<AGROW>
            end
        end
    end
    for drop_e = selected_e
        for add_e = unselected_e
            mask_e = bitset(bitset(elevation_mask, drop_e, 0), add_e, 1);
            for drop_a = selected_a
                for add_a = unselected_a
                    mask_a = bitset(bitset(azimuth_mask, drop_a, 0), add_a, 1);
                    [candidate, evaluation_count] = evaluate_masks_local( ...
                        mask_e, mask_a, context, evaluation_count);
                    if candidate.eta_design >= eta0
                        candidates{end + 1, 1} = candidate; %#ok<AGROW>
                    end
                end
            end
        end
    end
    if ~isempty(candidates)
        candidate = choose_feasible_local(candidates);
        if lexicographic_improvement_local(candidate, current)
            current = candidate;
            elevation_mask = current.elevation_mask_integer;
            azimuth_mask = current.azimuth_mask_integer;
            improved = true;
            rows{end + 1, 1} = trace_row_local( ...
                'PAIR_SWAP', current, evaluation_count); %#ok<AGROW>
        end
    end
end

result = current;
result.greedy_evaluation_count = evaluation_count;
result.greedy_runtime = toc(start_tic);
result.greedy_status = "GREEDY_EXACT_REEVALUATION_COMPLETE";
trace = struct2table(vertcat(rows{:}));
end

function [summary, count] = evaluate_masks_local(mask_e, mask_a, context, count)
family = context.plan.subset_family;
match = family.elevation_mask_integer == mask_e & ...
    family.azimuth_mask_integer == mask_a;
if nnz(match) ~= 1
    error('greedy_exchange_exact_subset_design:Mask', ...
        'Every nonempty mask pair must identify one registered subset.');
end
[summary, ~] = evaluate_stage7_subset(family(match, :), context, ...
    struct('return_detail', false));
count = count + summary.fim_evaluation_count;
end

function selected = choose_add_local(candidates)
table_now = struct2table(vertcat(candidates{:}));
table_now.lex_id = string(table_now.subset_id);
table_now = sortrows(table_now, ...
    {'eta_design','MAC_total','B_out','lex_id'}, ...
    {'descend','ascend','ascend','ascend'});
selected = table2struct(table_now(1, setdiff(table_now.Properties.VariableNames, ...
    {'lex_id'}, 'stable')));
end

function selected = choose_feasible_local(candidates)
table_now = struct2table(vertcat(candidates{:}));
table_now.lex_id = string(table_now.subset_id);
table_now = sortrows(table_now, ...
    {'MAC_total','B_out','eta_design','lex_id'}, ...
    {'ascend','ascend','descend','ascend'});
selected = table2struct(table_now(1, setdiff(table_now.Properties.VariableNames, ...
    {'lex_id'}, 'stable')));
end

function flag = lexicographic_improvement_local(candidate, current)
ids = sort([string(candidate.subset_id); string(current.subset_id)]);
candidate_lex_first = ids(1) == string(candidate.subset_id) && ...
    string(candidate.subset_id) ~= string(current.subset_id);
flag = candidate.MAC_total < current.MAC_total || ...
    (candidate.MAC_total == current.MAC_total && ...
    (candidate.B_out < current.B_out || ...
    (candidate.B_out == current.B_out && ...
    (candidate.eta_design > current.eta_design + 1e-12 || ...
    (abs(candidate.eta_design - current.eta_design) <= 1e-12 && ...
    candidate_lex_first)))));
end

function row = trace_row_local(operation, summary, count)
row = struct('operation', string(operation), ...
    'subset_id', string(summary.subset_id), ...
    'elevation_mask_integer', summary.elevation_mask_integer, ...
    'azimuth_mask_integer', summary.azimuth_mask_integer, ...
    'MAC_total', summary.MAC_total, 'B_out', summary.B_out, ...
    'eta_design', summary.eta_design, ...
    'cumulative_fim_evaluation_count', count);
end
