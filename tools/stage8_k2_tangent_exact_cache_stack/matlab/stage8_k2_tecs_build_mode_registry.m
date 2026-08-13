function output = stage8_k2_tecs_build_mode_registry(runtime_root)
%STAGE8_K2_TECS_BUILD_MODE_REGISTRY Resolve aliases to semantic modes.

design = jsondecode(fileread(fullfile(runtime_root, 'freeze', ...
    'design_freeze.json')));
rule = jsondecode(fileread(fullfile(runtime_root, 'freeze', ...
    'canonical_mode_construction_rule.json')));
c5 = jsondecode(fileread(fullfile(runtime_root, 'freeze', ...
    'c5_precedence_fallback_rule.json')));
disposition = readtable(fullfile(runtime_root, 'pass_a', ...
    'layer_disposition.csv'), 'TextType', 'string');
required = ["C1","C2","C3","C4","C5R","C5P","C6","C7"];
assert(isequal(string(disposition.cache_layer), required.'), ...
    'stage8_k2_tecs_build_mode_registry:Disposition');
admitted = disposition.integration_status == "INTEGRATION_ADMITTED";
admitted(disposition.cache_layer == "C1") = true;

sets = containers.Map('KeyType', 'char', 'ValueType', 'any');
sets('M0') = cell(0, 1);
current = {'C1'};
sets('M1') = current;
for index = 2:4
    layer = sprintf('C%d', index);
    row = disposition.cache_layer == string(layer);
    if any(row & admitted), current{end + 1, 1} = layer; end %#ok<AGROW>
    sets(sprintf('M%d', index)) = current;
end
sets('S0') = sets('M0');
sets('S1') = {'C1'};
sets('CM1') = sets('M1');
sets('CM2') = sets('M2');
sets('CM3') = sets('M3');
sets('CM4') = sets('M4');
sets('BLOO-C1') = setdiff(sets('M4'), {'C1'}, 'stable');
for index = 2:4
    layer = sprintf('C%d', index);
    row = disposition.cache_layer == string(layer);
    if any(row & admitted)
        sets(['S', num2str(index)]) = {layer};
        sets(['BLOO-', layer]) = setdiff(sets('M4'), {layer}, 'stable');
    end
end

aliases = sort(string(keys(sets))).';
mode_payloads = cell(numel(aliases), 1);
mode_ids = strings(numel(aliases), 1);
enabled_json = strings(numel(aliases), 1);
enabled_hash = strings(numel(aliases), 1);
for index = 1:numel(aliases)
    layers = reshape(cellstr(string(sets(char(aliases(index))))), [], 1);
    payload = semantic_payload_local(layers, c5);
    mode_payloads{index} = payload;
    mode_hash = stage8_k2_tecs_sha256( ...
        'TECS_CANONICAL_MODE_SEMANTIC_PAYLOAD_V1', payload);
    mode_ids(index) = "MODE_" + string(mode_hash);
    enabled_json(index) = string(jsonencode(layers));
    enabled_hash(index) = stage8_k2_tecs_sha256( ...
        'TECS_ENABLED_LAYER_SET_V1', layers);
end

[unique_ids, first] = unique(mode_ids, 'stable');
canonical_rows = repmat(canonical_template_local(), numel(unique_ids), 1);
representatives = strings(numel(unique_ids), 1);
for index = 1:numel(unique_ids)
    members = aliases(mode_ids == unique_ids(index));
    members = sort(members);
    representatives(index) = members(1);
    source = first(index);
    row = canonical_template_local();
    row.candidate_canonical_mode_id = unique_ids(index);
    row.ordered_enabled_layer_set = enabled_json(source);
    row.enabled_layer_set_hash = enabled_hash(source);
    row.representative_alias_id = representatives(index);
    row.enabled_layer_count = numel(mode_payloads{source}.ordered_enabled_layer_set);
    row.precedence_hash = string(c5.precedence_hash);
    row.fallback_hash = string(c5.fallback_hash);
    row.canonical_payload_hash = extractAfter(unique_ids(index), "MODE_");
    canonical_rows(index) = row;
end
canonical = struct2table(canonical_rows);
canonical = sortrows(canonical, 'candidate_canonical_mode_id');

alias_rows = repmat(alias_template_local(), numel(aliases), 1);
for index = 1:numel(aliases)
    row = alias_template_local();
    row.variant_alias_id = aliases(index);
    row.candidate_canonical_mode_id = mode_ids(index);
    row.alias_of_canonical_mode_id = mode_ids(index);
    row.ordered_enabled_layer_set = enabled_json(index);
    row.enabled_layer_set_hash = enabled_hash(index);
    row.representative_alias_id = representatives( ...
        unique_ids == mode_ids(index));
    row.precedence_hash = string(c5.precedence_hash);
    row.fallback_hash = string(c5.fallback_hash);
    alias_rows(index) = row;
end
aliases_table = sortrows(struct2table(alias_rows), 'variant_alias_id');

if height(canonical) ~= 2
    error('stage8_k2_tecs_build_mode_registry:Ambiguity', ...
        ['CANONICAL_MODE_REGISTRY_AMBIGUITY_STOP: expected only ', ...
        'CACHE_OFF and required C1 semantic modes.']);
end
registry_payload = struct('canonical', table2struct(canonical), ...
    'aliases', table2struct(aliases_table), 'construction_rule_hash', ...
    design.canonical_mode_construction_rule_hash, ...
    'precedence_hash', c5.precedence_hash, ...
    'fallback_hash', c5.fallback_hash);
output = struct( ...
    'schema_version', 'STAGE8_K2_TECS_MODE_REGISTRY_V1', ...
    'canonical', canonical, 'aliases', aliases_table, ...
    'canonical_mode_registry_hash', stage8_k2_tecs_sha256( ...
        'TECS_CANONICAL_MODE_REGISTRY_V1', table2struct(canonical)), ...
    'mode_alias_registry_hash', stage8_k2_tecs_sha256( ...
        'TECS_MODE_ALIAS_REGISTRY_V1', table2struct(aliases_table)), ...
    'representative_alias_rule_hash', stage8_k2_tecs_sha256( ...
        'TECS_REPRESENTATIVE_ALIAS_RULE_V1', registry_payload), ...
    'precedence_hash', c5.precedence_hash, ...
    'fallback_hash', c5.fallback_hash, ...
    'construction_rule_hash', ...
        design.canonical_mode_construction_rule_hash, ...
    'rule_schema_version', rule.schema_version);
end

function payload = semantic_payload_local(layers, c5)
scope = repmat(struct('cache_layer', '', 'scope', '', ...
    'population_class', '', 'output_class', ''), numel(layers), 1);
for index = 1:numel(layers)
    layer = layers{index};
    scope(index).cache_layer = layer;
    switch layer
        case 'C1'
            scope(index).scope = 'MEASUREMENT_IDENTITY_SESSION';
            scope(index).population_class = 'PREBUILT_FINITE_DOMAIN';
            scope(index).output_class = ...
                'CERTIFIED_CANONICAL_DICTIONARY_OUTPUT';
        otherwise
            error('stage8_k2_tecs_build_mode_registry:UnexpectedLayer', ...
                'A non-admitted layer reached the canonical registry: %s.', ...
                layer);
    end
end
payload = struct( ...
    'schema_version', 'STAGE8_K2_TECS_CANONICAL_MODE_PAYLOAD_V1', ...
    'ordered_enabled_layer_set', {layers}, ...
    'scope_and_population_per_layer', scope, ...
    'C5P_supersede_C1_rule', false, ...
    'precedence_hash', c5.precedence_hash, ...
    'fallback_hash', c5.fallback_hash, ...
    'dependency_rules', struct('C5R_requires_C1', true, ...
        'C5R_C5P_mutually_exclusive', true, ...
        'production_default_cache_setting', 'CACHE_OFF'));
end

function row = canonical_template_local()
row = struct('candidate_canonical_mode_id', "", ...
    'ordered_enabled_layer_set', "", 'enabled_layer_set_hash', "", ...
    'representative_alias_id', "", 'enabled_layer_count', 0, ...
    'precedence_hash', "", 'fallback_hash', "", ...
    'canonical_payload_hash', "");
end

function row = alias_template_local()
row = struct('variant_alias_id', "", ...
    'candidate_canonical_mode_id', "", ...
    'alias_of_canonical_mode_id', "", ...
    'ordered_enabled_layer_set', "", 'enabled_layer_set_hash', "", ...
    'representative_alias_id', "", 'precedence_hash', "", ...
    'fallback_hash', "");
end
