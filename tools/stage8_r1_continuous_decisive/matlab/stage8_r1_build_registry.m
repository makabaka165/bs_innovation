function registry = stage8_r1_build_registry(context, registry_kind)
%STAGE8_R1_BUILD_REGISTRY Build formal or gate-fixture trial registries.

if nargin < 2, registry_kind = 'FORMAL'; end
registry_kind = upper(char(string(registry_kind)));
switch registry_kind
    case 'FORMAL'
        registry = formal_registry_local();
    case 'R2'
        registry = r2_registry_local();
    case 'R3'
        formal = formal_registry_local();
        registry = formal(ismember(formal.global_trial_index, ...
            [1, 16, 17, 24]), :);
    otherwise
        error('stage8_r1_build_registry:Kind', ...
            'Unsupported registry kind: %s.', registry_kind);
end
if nargin >= 1 && isstruct(context) && isfield(context, 'plan')
    bounds = context.plan.local_domain.domain_bounds_deg;
    if any(registry.center_az_deg < bounds(1) | ...
            registry.center_az_deg > bounds(2) | ...
            registry.center_el_deg < bounds(3) | ...
            registry.center_el_deg > bounds(4))
        error('stage8_r1_build_registry:Domain', ...
            'A registry center lies outside the frozen local domain.');
    end
end
end

function registry = formal_registry_local()
rows = cell(24, 1);
global_index = 0;
combination_index = 0;
noise_ids = ["WHITE";"STAGE5_TOEPLITZ_CORRELATED"];
for noise_index = 1:2
    for L = [1, 8]
        for snr_db = [-6, 6]
            seed = 2726072800 + combination_index;
            combination_index = combination_index + 1;
            for support = ["ON_GRID","INSIDE_OFF_GRID"]
                global_index = global_index + 1;
                center = [8.0, 10.0];
                if support == "INSIDE_OFF_GRID", center = [8.1, 10.1]; end
                id = sprintf('R1_K1_N%d_L%d_S%s_%s', noise_index, L, ...
                    signed_token_local(snr_db), char(support));
                rows{global_index} = row_local(global_index, id, 1, ...
                    support, noise_ids(noise_index), L, snr_db, seed, ...
                    center, NaN, NaN);
            end
        end
    end
end
combination_index = 0;
for noise_index = 1:2
    for L = [4, 8]
        seed = 2726072900 + combination_index;
        combination_index = combination_index + 1;
        for difficulty = ["EASY","MODERATE"]
            if difficulty == "EASY"
                separation = 0.30;
                snr_db = 6;
            else
                separation = 0.15;
                snr_db = 0;
            end
            global_index = global_index + 1;
            id = sprintf('R1_K2_N%d_L%d_%s', noise_index, L, ...
                char(difficulty));
            rows{global_index} = row_local(global_index, id, 2, ...
                difficulty, noise_ids(noise_index), L, snr_db, seed, ...
                [8.0, 10.0], separation, 45);
        end
    end
end
registry = struct2table(vertcat(rows{:}));
if height(registry) ~= 24 || nnz(registry.truth_K == 1) ~= 16 || ...
        nnz(registry.truth_K == 2) ~= 8 || ...
        numel(unique(registry.trial_id)) ~= 24
    error('stage8_r1_build_registry:Cardinality', ...
        'Formal registry cardinality is invalid.');
end
end

function registry = r2_registry_local()
noise = "WHITE";
rows = [row_local(1, 'R1_GATE_F1_K1_ON_GRID', 1, "ON_GRID", ...
    noise, 4, 6, 2726072991, [8.0, 10.0], NaN, NaN); ...
    row_local(2, 'R1_GATE_F2_K1_INSIDE_OFF_GRID', 1, ...
    "INSIDE_OFF_GRID", noise, 4, 6, 2726072992, ...
    [8.1, 10.1], NaN, NaN)];
registry = struct2table(rows);
end

function row = row_local(index, id, truth_K, label, noise, L, snr, seed, ...
    center, separation, direction)
row = struct('global_trial_index', double(index), ...
    'trial_id', string(id), 'truth_K', double(truth_K), ...
    'trial_type', string(sprintf('K%d', truth_K)), ...
    'support_or_difficulty', string(label), ...
    'noise_profile_id', string(noise), 'L', double(L), ...
    'snr_db', double(snr), 'noise_seed', double(seed), ...
    'center_az_deg', double(center(1)), ...
    'center_el_deg', double(center(2)), ...
    'separation_deg', double(separation), ...
    'direction_deg', double(direction), ...
    'secondary_power_db', 0, 'correlation_magnitude', 0, ...
    'correlation_phase_rad', 0, 'expected_method_rows', 3);
end

function value = signed_token_local(number)
if number < 0, value = sprintf('M%d', abs(number)); ...
else, value = sprintf('P%d', number); end
end
