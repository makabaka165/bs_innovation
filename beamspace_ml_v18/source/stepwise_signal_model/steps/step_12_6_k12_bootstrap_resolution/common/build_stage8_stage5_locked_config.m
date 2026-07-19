function locked = build_stage8_stage5_locked_config()
%BUILD_STAGE8_STAGE5_LOCKED_CONFIG Expose the frozen Stage5 init contract.

locked = struct();
locked.conventional_center_deg = [8, 10];
locked.az_beam_deg = [7.4, 8.0, 8.6];
locked.el_beam_deg = [9.6, 10.0, 10.4];
locked.azimuth_offsets_deg = -0.6:0.2:0.6;
locked.elevation_offsets_deg = -0.2:0.2:0.2;
locked.max_iter = 6;
locked.relative_score_tolerance = 1e-9;
locked.angle_tolerance_deg = 0;
locked.main_num_multi_start = 1;
locked.direct_num_multi_start = 2;
locked.success_gate_az_deg = 0.21;
locked.success_gate_el_deg = 0.21;
locked.wrong_peak_gate_pair_deg = 0.45;
locked.penalty_pair_error_deg = sqrt(0.6 ^ 2 + 0.2 ^ 2);
locked.configuration_hash = build_stage5_configuration_hash(locked);
locked.stage8_role = 'INITIALIZATION_ONLY';
locked.phase_factor = 1;
end
