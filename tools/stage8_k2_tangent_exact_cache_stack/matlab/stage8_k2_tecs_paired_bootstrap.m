function output = stage8_k2_tecs_paired_bootstrap(raw, registry)
%STAGE8_K2_TECS_PAIRED_BOOTSTRAP Fixed-registry AB/BA bootstrap.

resamples = 10000;
identity_hashes = unique(raw.fixed_measurement_hash, 'stable');
assert(numel(identity_hashes) == 2 && height(registry) == 72);
trial_bootstrap = zeros(72, resamples);
implementation = struct( ...
    'generator','THREEFRY_SUBSTREAM_PER_TRIAL_DIRECTION', ...
    'base_seed_rule','first uint32 of SHA256(2026080901|trial|direction)', ...
    'substream_rule','replicate index 1..10000', ...
    'draws_per_substream',10, ...
    'AB_BA_separate',true,'fixed_trial_registry',true);
for trial_index = 1:72
    trial_id = string(registry.trial_id(trial_index));
    samples = raw(raw.trial_id == trial_id, :);
    ab = samples.paired_difference_sec(samples.pair_order == "AB");
    ba = samples.paired_difference_sec(samples.pair_order == "BA");
    assert(numel(ab) == 10 && numel(ba) == 10);
    stream_ab = RandStream('Threefry', 'Seed', ...
        seed_local(2026080901, trial_id, 'AB'));
    stream_ba = RandStream('Threefry', 'Seed', ...
        seed_local(2026080901, trial_id, 'BA'));
    for replicate = 1:resamples
        stream_ab.Substream = replicate;
        stream_ba.Substream = replicate;
        sampled_ab = ab(randi(stream_ab, 10, [10, 1]));
        sampled_ba = ba(randi(stream_ba, 10, [10, 1]));
        trial_bootstrap(trial_index, replicate) = ...
            median([sampled_ab; sampled_ba]);
    end
end
identity_values = zeros(2, resamples);
for index = 1:2
    members = raw.fixed_measurement_hash == identity_hashes(index);
    trial_ids = unique(raw.trial_id(members), 'stable');
    indices = zeros(numel(trial_ids), 1);
    for trial_index = 1:numel(trial_ids)
        indices(trial_index) = find( ...
            string(registry.trial_id) == trial_ids(trial_index), 1);
    end
    identity_values(index, :) = sum(trial_bootstrap(indices, :), 1);
end
overall_values = sum(trial_bootstrap, 1);
sorted_overall = sort(overall_values);
identity_lower = zeros(2, 1);
for index = 1:2
    sorted_identity = sort(identity_values(index, :));
    identity_lower(index) = sorted_identity(500);
end
output = struct( ...
    'schema_version','STAGE8_K2_TECS_FIXED_REGISTRY_BOOTSTRAP_V1', ...
    'bootstrap_seed',2026080901,'resample_count',resamples, ...
    'lower_order_statistic_index',500, ...
    'identity_hashes',{cellstr(identity_hashes)}, ...
    'identity_lower_sec',identity_lower, ...
    'overall_lower_sec',sorted_overall(500), ...
    'implementation',implementation, ...
    'implementation_hash',stage8_k2_tecs_sha256( ...
        'TECS_BOOTSTRAP_IMPLEMENTATION_V1',implementation));
end
function seed = seed_local(base, trial_id, direction)
hash = stage8_k2_tecs_sha256('TECS_BOOTSTRAP_STREAM_SEED_V1', ...
    struct('bootstrap_seed',base,'trial_id',char(trial_id), ...
    'direction',direction));
seed = double(uint32(hex2dec(hash(1:8))));
if seed == 0, seed = 1; end
end
