function resources = stage8_k2_rtc_prepare_resources(model, domain, mode)
b = domain.domain_bounds_deg;
az = b(1)+(0:round((b(2)-b(1))/.005))*.005;
el = b(3)+(0:round((b(4)-b(3))/.005))*.005;
az(end)=b(2); el(end)=b(4);
[aa,ee] = ndgrid(az,el);
points = [aa(:) ee(:)];
timer = tic;
physical = build_stage8_element_manifold(points, model);
entry = struct('G_beamspace', [], 'A_element_white', [], ...
    'standalone_precompute_runtime_sec', 0);
if string(mode)=="BEAMSPACE"
    entry.G_beamspace = model.T_I*(model.W_I'*physical.A);
else
    entry.A_element_white = physical.A;
end
resources = struct('entry', entry, 'az_grid_deg', az, 'el_grid_deg', el, ...
    'grid_points_deg', points, 'grid_size', size(aa), 'grid_point_count', size(points,1), ...
    'precompute_runtime_sec', toc(timer));
end
