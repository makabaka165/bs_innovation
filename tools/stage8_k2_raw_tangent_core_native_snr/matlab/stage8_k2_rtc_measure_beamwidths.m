function widths = stage8_k2_rtc_measure_beamwidths(context)
c = stage8_k2_rtc_constants();
geometry = struct('xMat', context.model.array_meta.XAct, ...
    'yMat', context.model.array_meta.YAct, 'zMat', context.model.array_meta.ZAct);
rows = cell(numel(c.profile_ids), 1);
for p = 1:numel(c.profile_ids)
    center = c.profile_values(p, 1:2);
    az = analyze_reference_beam('azimuth', context.cfg, geometry, center(1), center(2));
    el = analyze_reference_beam('elevation', context.cfg, geometry, center(1), center(2));
    for info = {az, el}
        v = info{1};
        [~, peak] = max(v.patternDb);
        assert(any(v.patternDb(1:peak) < -3) && any(v.patternDb(peak:end) < -3));
        assert(isfinite(v.bw3dB) && v.bw3dB > 0);
    end
    rows{p} = struct('profile_id', c.profile_ids(p), 'center_az_deg', center(1), ...
        'center_el_deg', center(2), 'az_bw_3db_deg', az.bw3dB, ...
        'el_bw_3db_deg', el.bw3dB, 'az_left_cross_deg', az.leftCross, ...
        'az_right_cross_deg', az.rightCross, 'el_left_cross_deg', el.leftCross, ...
        'el_right_cross_deg', el.rightCross, ...
        'configuration_hash', string(context.configuration_hash));
end
widths = struct2table(vertcat(rows{:}));
digest = stage8_k2_rtc_hash(widths);
widths.beamwidth_contract_hash = repmat(string(digest), numel(c.profile_ids), 1);
end
