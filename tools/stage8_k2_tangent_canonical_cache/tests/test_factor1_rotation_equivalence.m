function result = test_factor1_rotation_equivalence()
%TEST_FACTOR1_ROTATION_EQUIVALENCE Verify physical/canonical rotations.

fixture = stage8_k2_tcc_test_fixture();
model = fixture.model;
geometry = stage8_k2_tcc_build_canonical_geometry(model);
center = geometry.center_column;
count = numel(geometry.phi_col_deg);
columns = mod([center, center + 23, center - 31] - 1, count) + 1;
deltas = [-0.45, 0, 0.37];
elevations = [9.8, 10.0, 10.2];
k0 = 2 * pi / model.lambda;
max_element_error = 0;
max_G_error = 0;
for center_index = 1:numel(columns)
    phi = wrap180_local(geometry.phi_col_deg(columns(center_index)));
    r_actual = rotation_z_local(phi) * geometry.r_canonical;
    for sample_index = 1:numel(deltas)
        delta = deltas(sample_index);
        elevation = elevations(sample_index);
        actual_u = direction_local(phi + delta, elevation);
        canonical_u = direction_local(delta, elevation);
        actual_a = exp(1i * k0 * (r_actual.' * actual_u));
        canonical_a = exp(1i * k0 * ...
            (geometry.r_canonical.' * canonical_u));
        element_error = norm(actual_a - canonical_a) / ...
            max(norm(actual_a), realmin);
        actual_G = model.Tseq * (model.Wseq' * actual_a);
        canonical_G = model.Tseq * (model.Wseq' * canonical_a);
        G_error = norm(actual_G - canonical_G) / ...
            max(norm(actual_G), realmin);
        max_element_error = max(max_element_error, element_error);
        max_G_error = max(max_G_error, G_error);
    end
end
assert(geometry.rotation_equivalence_flag && ...
    max_element_error <= 1e-11 && max_G_error <= 1e-10, ...
    'test_factor1_rotation_equivalence:Mismatch', ...
    'Factor-1 rotation equivalence failed.');
result = struct('pass', true, ...
    'max_element_relative_error', max_element_error, ...
    'max_whitened_G_relative_error', max_G_error, ...
    'geometry_roundtrip_error', geometry.roundtrip_error);
fprintf(['test_factor1_rotation_equivalence PASS element=%.17g ', ...
    'G=%.17g\n'], max_element_error, max_G_error);
end

function u = direction_local(azimuth_deg, elevation_deg)
u = [cosd(elevation_deg) * cosd(azimuth_deg); ...
    cosd(elevation_deg) * sind(azimuth_deg); sind(elevation_deg)];
end

function R = rotation_z_local(angle_deg)
R = [cosd(angle_deg), -sind(angle_deg), 0; ...
    sind(angle_deg), cosd(angle_deg), 0; 0, 0, 1];
end

function angle = wrap180_local(angle)
angle = mod(angle + 180, 360) - 180;
end
