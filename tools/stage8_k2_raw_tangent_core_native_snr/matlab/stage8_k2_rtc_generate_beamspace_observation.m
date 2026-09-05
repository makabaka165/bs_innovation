function observation = stage8_k2_rtc_generate_beamspace_observation(Xw, target_db, seed)
assert(size(Xw, 1) == 15);
observation = stage8_k2_rtc_generate_observation(Xw, target_db, seed, 'BEAMSPACE');
end
