function [pool, cfg] = stage8_k2_mc_build_rotated_candidate_pool(spec, center)
%STAGE8_K2_MC_BUILD_ROTATED_CANDIDATE_POOL Rebuild one co-rotated 5x5 pool.

cfg = spec.cfg;
cfg.beam.azSectorCenter = center.requested_center_az_deg;
cfg.beam.azSteer = center.requested_center_az_deg;
azimuth_beam_deg = spec.reference_pool.azimuth_beam_deg + ...
    center.rotation_delta_deg;
elevation_beam_deg = spec.reference_pool.elevation_beam_deg;
array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
if array_meta.colCtr ~= center.center_column
    error('stage8_k2_mc_build_rotated_candidate_pool:CenterColumn', ...
        'BLOCKED_PHYSICAL_CENTER_SELECTION_MISMATCH.');
end
N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
[~, V] = form_elevation_dbf_cube(complex(zeros(N_el, N_az)), ...
    elevation_beam_deg, cfg);
[~, Uset] = form_azimuth_dbf_cube( ...
    complex(zeros(numel(elevation_beam_deg), N_az)), ...
    azimuth_beam_deg, elevation_beam_deg, cfg);
[W0, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta);

candidate_table = spec.reference_pool.table;
candidate_table.azimuth_beam_deg = ...
    candidate_table.azimuth_beam_deg + center.rotation_delta_deg;
for index = 1:height(candidate_table)
    candidate_table.physical_weight_hash(index) = ...
        string(stage7_stable_hash(W0(:, index)));
end
candidate_table.candidate_pool_source(:) = ...
    "STAGE8_K2_MC_CO_ROTATED_PRODUCTION_5X5";

pool = struct();
pool.W0 = W0;
pool.V = V;
pool.Uset = Uset;
pool.table = candidate_table;
pool.array_meta = array_meta;
pool.beam_meta = beam_meta;
pool.azimuth_beam_deg = azimuth_beam_deg;
pool.elevation_beam_deg = elevation_beam_deg;
pool.center_3x3_elevation_indices = ...
    spec.reference_pool.center_3x3_elevation_indices;
pool.center_3x3_azimuth_indices = ...
    spec.reference_pool.center_3x3_azimuth_indices;
pool.W0_hash = stage7_stable_hash(W0);
pool.array_geometry_hash = stage7_stable_hash(array_meta.XAct, ...
    array_meta.YAct, array_meta.ZAct, cfg.arr.lambda, ...
    beam_meta.element_vector_order);
pool.source_status = 'CO_ROTATED_CYLINDRICAL_PRODUCTION_POOL';
pool.phase_factor = 1;
pool.center_column = center.center_column;
pool.requested_center_az_deg = center.requested_center_az_deg;
pool.physical_center_az_deg = center.physical_center_az_deg;
pool.physical_center_unwrapped_az_deg = ...
    center.physical_center_unwrapped_az_deg;
pool.rotation_delta_deg = center.rotation_delta_deg;
end
