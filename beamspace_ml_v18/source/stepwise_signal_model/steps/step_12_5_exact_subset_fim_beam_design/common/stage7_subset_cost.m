function cost = stage7_subset_cost(B_e, B_a, cfg)
%STAGE7_SUBSET_COST Return the registered two-stage physical cost.

validateattributes(B_e, {'numeric'}, {'scalar','integer','positive'});
validateattributes(B_a, {'numeric'}, {'scalar','integer','positive'});
N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
cost = struct();
cost.B_e = B_e;
cost.B_a = B_a;
cost.B_out = B_e * B_a;
cost.MAC_el = B_e * N_el * N_az;
cost.MAC_az = B_e * B_a * N_az;
cost.MAC_total = cost.MAC_el + cost.MAC_az;
cost.output_channel_count = cost.B_out;
cost.output_bytes_complex_double = 16 * cost.B_out;
cost.weight_memory_bytes = 16 * N_el * N_az * cost.B_out;
cost.estimated_data_movement_bytes = 16 * (N_el * N_az + cost.B_out);
conventional_cost = N_el * N_az + N_az;
cost.incremental_cost_over_conventional = cost.MAC_total - conventional_cost;
end
