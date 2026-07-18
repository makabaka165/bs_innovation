function pool = build_stage7_candidate_pool(cfg)
%BUILD_STAGE7_CANDIDATE_POOL Build the registered factor-1 fallback pool.

if cfg.beam.spatialPhaseFactor ~= 1
    error('build_stage7_candidate_pool:PhaseFactor', ...
        'Stage 7 requires spatialPhaseFactor=1.');
end
azimuth_beam_deg = [6.8, 7.4, 8.0, 8.6, 9.2];
elevation_beam_deg = [9.2, 9.6, 10.0, 10.4, 10.8];
array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
[~, V] = form_elevation_dbf_cube(complex(zeros(N_el, N_az)), ...
    elevation_beam_deg, cfg);
[~, Uset] = form_azimuth_dbf_cube( ...
    complex(zeros(numel(elevation_beam_deg), N_az)), ...
    azimuth_beam_deg, elevation_beam_deg, cfg);
[W0, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta);

B_e = numel(elevation_beam_deg);
B_a = numel(azimuth_beam_deg);
B_out = B_e * B_a;
sequential_channel_id = (1:B_out).';
global_elevation_beam_id = beam_meta.el_channel_index;
global_azimuth_beam_id = beam_meta.az_beam_index;
elevation_deg = zeros(B_out, 1);
azimuth_deg = zeros(B_out, 1);
parent_elevation_channel_id = global_elevation_beam_id;
physical_weight_hash = strings(B_out, 1);
column_index_in_W0 = sequential_channel_id;
for index = 1:B_out
    elevation_deg(index) = elevation_beam_deg(global_elevation_beam_id(index));
    azimuth_deg(index) = azimuth_beam_deg(global_azimuth_beam_id(index));
    physical_weight_hash(index) = stage7_stable_hash(W0(:, index));
end
source_id = repmat("REGISTERED_STAGE7_FALLBACK_5X5", B_out, 1);
candidate_table = table(sequential_channel_id, global_elevation_beam_id, ...
    global_azimuth_beam_id, elevation_deg, azimuth_deg, ...
    parent_elevation_channel_id, physical_weight_hash, ...
    column_index_in_W0, source_id, 'VariableNames', ...
    {'sequential_channel_id','global_elevation_beam_id', ...
    'global_azimuth_beam_id','elevation_beam_deg','azimuth_beam_deg', ...
    'parent_elevation_channel_id','physical_weight_hash', ...
    'column_index_in_W0','candidate_pool_source'});

pool = struct();
pool.W0 = W0;
pool.V = V;
pool.Uset = Uset;
pool.table = candidate_table;
pool.array_meta = array_meta;
pool.beam_meta = beam_meta;
pool.azimuth_beam_deg = azimuth_beam_deg;
pool.elevation_beam_deg = elevation_beam_deg;
pool.center_3x3_elevation_indices = 2:4;
pool.center_3x3_azimuth_indices = 2:4;
pool.W0_hash = stage7_stable_hash(W0);
pool.array_geometry_hash = stage7_stable_hash(array_meta.XAct, ...
    array_meta.YAct, array_meta.ZAct, cfg.arr.lambda, ...
    beam_meta.element_vector_order);
pool.source_status = 'FROZEN_FALLBACK_NO_EXISTING_UNIFIED_5X5_POOL';
pool.phase_factor = 1;
end
