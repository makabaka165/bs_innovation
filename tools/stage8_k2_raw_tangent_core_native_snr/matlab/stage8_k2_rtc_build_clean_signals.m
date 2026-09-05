function clean = stage8_k2_rtc_build_clean_signals(spec, model)
angles = stage8_k2_rtc_build_truth(spec);
[source, info] = stage8_k2_rtc_build_source(spec);
physical = build_stage8_element_manifold(angles, model);
Xe = physical.A * source;
Xw = model.T_I * (model.W_I' * Xe);
clean = struct('truth', angles, 'source', source, 'source_info', info, ...
    'Xe', Xe, 'Xw', Xw, 'truth_hash', stage8_k2_rtc_hash(angles), ...
    'source_hash', stage8_k2_rtc_hash(source));
end
