function schedule = stage8_k2_tecs_build_component_schedule(design, cache_layers)
%STAGE8_K2_TECS_BUILD_COMPONENT_SCHEDULE Deterministic frozen pair order.

if nargin < 2 || isempty(cache_layers), cache_layers = {'C1'}; end
cache_layers = cellstr(upper(string(cache_layers(:))));
if ~(isstruct(design) && isscalar(design) && ...
        isfield(design, 'measurement_identity_hashes') && ...
        numel(design.measurement_identity_hashes) == 2)
    error('stage8_k2_tecs_build_component_schedule:Design', ...
        'The design freeze must contain exactly two identities.');
end
if numel(unique(string(cache_layers))) ~= numel(cache_layers)
    error('stage8_k2_tecs_build_component_schedule:Layers', ...
        'Component layers must be unique.');
end
seed = 2026080906;
rows = repmat(row_template_local(), 0, 1);
for layer_index = 1:numel(cache_layers)
    layer = cache_layers{layer_index};
    for identity_index = 1:2
        identity = char(string( ...
            design.measurement_identity_hashes{identity_index}));
        warmup = { ...
            {'AB','BA','AB','BA','AB'}, ...
            {'BA','AB','BA','AB','BA'}};
        for repeat_index = 1:5
            row = row_template_local();
            row.cache_layer = string(layer);
            row.fixed_measurement_hash = string(identity);
            row.identity_index = identity_index;
            row.identity_batch_id = string(sprintf( ...
                'C1_IDENTITY_%02d_36_TRIAL_EVENT_STREAM', identity_index));
            row.batch_repeat_index = repeat_index;
            row.pair_order = string(warmup{identity_index}{repeat_index});
            row.schedule_phase = "WARMUP";
            row.included_in_statistics = 0;
            row.order_key = "NOT_APPLICABLE_FIXED_WARMUP";
            rows(end + 1, 1) = row; %#ok<AGROW>
        end
        measured = [repmat("AB", 15, 1); repmat("BA", 15, 1)];
        candidates = repmat(row_template_local(), 30, 1);
        for repeat_index = 1:30
            candidates(repeat_index).cache_layer = string(layer);
            candidates(repeat_index).fixed_measurement_hash = ...
                string(identity);
            candidates(repeat_index).identity_index = identity_index;
            candidates(repeat_index).identity_batch_id = string(sprintf( ...
                'C1_IDENTITY_%02d_36_TRIAL_EVENT_STREAM', identity_index));
            candidates(repeat_index).batch_repeat_index = repeat_index;
            candidates(repeat_index).pair_order = measured(repeat_index);
            candidates(repeat_index).schedule_phase = "MEASURED";
            candidates(repeat_index).included_in_statistics = 1;
            candidates(repeat_index).order_key = string(component_key_local( ...
                seed, layer, identity, repeat_index, measured(repeat_index)));
        end
        candidate_table = struct2table(candidates);
        candidate_table = sortrows(candidate_table, ...
            {'order_key','batch_repeat_index','pair_order'}, ...
            {'ascend','ascend','ascend'});
        candidates = table2struct(candidate_table);
        rows = [rows; candidates]; %#ok<AGROW>
    end
end
schedule = struct2table(rows);
schedule.schedule_row_id = (1:height(schedule)).';
schedule.component_pair_order_seed(:) = seed;
schedule.schema_version(:) = "STAGE8_K2_TECS_COMPONENT_SCHEDULE_V1";
schedule = movevars(schedule, {'schema_version','schedule_row_id'}, ...
    'Before', 1);
schedule.schedule_row_hash = strings(height(schedule), 1);
hash_columns = setdiff(schedule.Properties.VariableNames, ...
    {'schedule_row_hash'}, 'stable');
for index = 1:height(schedule)
    schedule.schedule_row_hash(index) = string( ...
        stage8_k2_tcc_stable_hash('TECS_COMPONENT_SCHEDULE_ROW_V1', ...
        schedule(index, hash_columns)));
end
validate_local(schedule, cache_layers);
end

function row = row_template_local()
row = struct('cache_layer',"",'fixed_measurement_hash',"", ...
    'identity_index',0,'identity_batch_id',"", ...
    'batch_repeat_index',0,'pair_order',"",'schedule_phase',"", ...
    'included_in_statistics',0,'order_key',"");
end

function digest = component_key_local(seed, layer, identity, repeat, direction)
fields = {'COMPONENT_PAIR_ORDER',sprintf('%.0f', seed), ...
    char(layer),char(identity),sprintf('%d', repeat),char(direction)};
payload = unicode2native(strjoin(fields, '|'), 'UTF-8');
hasher = java.security.MessageDigest.getInstance('SHA-256');
hasher.update(typecast(uint8(payload), 'int8'));
raw = hasher.digest();
digest = lower(reshape(dec2hex(mod(double(raw), 256), 2).', 1, []));
end

function validate_local(schedule, cache_layers)
expected = 70 * numel(cache_layers);
assert(height(schedule) == expected && ...
    numel(unique(schedule.schedule_row_id)) == expected && ...
    numel(unique(schedule.schedule_row_hash)) == expected);
for layer = string(cache_layers(:)).'
    for identity = 1:2
        select = schedule.cache_layer == layer & ...
            schedule.identity_index == identity;
        current = schedule(select, :);
        assert(height(current) == 35 && ...
            nnz(~current.included_in_statistics) == 5 && ...
            nnz(current.included_in_statistics) == 30);
        measured = current(current.included_in_statistics == 1, :);
        assert(nnz(measured.pair_order == "AB") == 15 && ...
            nnz(measured.pair_order == "BA") == 15);
    end
end
end
