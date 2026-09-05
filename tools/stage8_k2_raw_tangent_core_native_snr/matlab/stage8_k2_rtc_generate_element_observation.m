function observation = stage8_k2_rtc_generate_element_observation(Xe, target_db, seed)
assert(size(Xe, 1) == 2080);
observation = stage8_k2_rtc_generate_observation(Xe, target_db, seed, 'ELEMENT');
end
