function geometry = stage8_k2_tcc_build_canonical_geometry(model, options)
%STAGE8_K2_TCC_BUILD_CANONICAL_GEOMETRY Rotate the active subarray to zero.

if nargin < 2 || isempty(options)
    options = struct();
end
validate_model_local(model);
meta = model.array_meta;
requested_center = double(meta.azCtr);
center_column = double(meta.colCtr);
phi_col = double(meta.phiCol(:).');
if ~isscalar(center_column) || ~isfinite(center_column) || ...
        center_column ~= fix(center_column) || center_column < 1 || ...
        center_column > numel(phi_col)
    error('stage8_k2_tcc_build_canonical_geometry:CenterColumn', ...
        'array_meta.colCtr must identify one physical column.');
end
measurement_center = wrap180_local(phi_col(center_column));

% The legacy receive vector is [azimuth-column, elevation-row] order.
% Apply the repository mapping before rotating so Wseq sees the same rows.
x_actual = canonical_coordinate_local(meta.XAct(:), meta);
y_actual = canonical_coordinate_local(meta.YAct(:), meta);
z_actual = canonical_coordinate_local(meta.ZAct(:), meta);
r_actual = [x_actual.'; y_actual.'; z_actual.'];
rotation = rotation_z_local(-measurement_center);
r_canonical = rotation * r_actual;
r_roundtrip = rotation_z_local(measurement_center) * r_canonical;
roundtrip_error = max(abs(r_roundtrip(:) - r_actual(:)));

if isfield(options, 'canonical_element_order') && ...
        ~isempty(options.canonical_element_order)
    element_order = options.canonical_element_order;
elseif isfield(model, 'element_order')
    element_order = model.element_order;
else
    element_order = 'repository_canonical_vector_order';
end
array_geometry_hash = stage8_k2_tcc_stable_hash( ...
    'ACTUAL_CANONICAL_ORDER_COORDINATES', r_actual, element_order);
canonical_geometry_hash = stage8_k2_tcc_stable_hash( ...
    'ROTATED_CANONICAL_COORDINATES', r_canonical, element_order);

geometry = struct();
geometry.requested_center_az_deg = requested_center;
geometry.measurement_center_az_deg = measurement_center;
geometry.center_column = center_column;
geometry.phi_col_deg = phi_col;
geometry.element_order = element_order;
geometry.canonical_element_order = element_order;
geometry.r_actual = r_actual;
geometry.r_canonical = r_canonical;
geometry.x_actual = r_actual(1, :).';
geometry.y_actual = r_actual(2, :).';
geometry.z_actual = r_actual(3, :).';
geometry.x_canonical = r_canonical(1, :).';
geometry.y_canonical = r_canonical(2, :).';
geometry.z_canonical = r_canonical(3, :).';
geometry.N_elements = size(r_actual, 2);
geometry.array_geometry_hash = array_geometry_hash;
geometry.canonical_geometry_hash = canonical_geometry_hash;
geometry.roundtrip_error = roundtrip_error;
geometry.rotation_equivalence_flag = roundtrip_error <= ...
    256 * eps(max(1, max(abs(r_actual(:)))));
geometry.local_column_order = get_field_local(meta, 'colsAct', []);
geometry.canonicalization_mapping = ...
    'reshape_cyl_vector_to_matrix_then_matrix_colon';
end

function vector = canonical_coordinate_local(legacy_vector, array_meta)
matrix = reshape_cyl_vector_to_matrix(legacy_vector, array_meta);
vector = double(matrix(:));
end

function validate_model_local(model)
required = {'array_meta'};
if ~(isstruct(model) && isscalar(model) && all(isfield(model, required)))
    error('stage8_k2_tcc_build_canonical_geometry:Model', ...
        'model must contain array_meta.');
end
required_meta = {'XAct','YAct','ZAct','azCtr','colCtr','phiCol'};
if ~all(isfield(model.array_meta, required_meta))
    error('stage8_k2_tcc_build_canonical_geometry:ArrayMeta', ...
        'array_meta is missing an active geometry field.');
end
if ~isequal(size(model.array_meta.XAct), size(model.array_meta.YAct)) || ...
        ~isequal(size(model.array_meta.XAct), size(model.array_meta.ZAct))
    error('stage8_k2_tcc_build_canonical_geometry:ArrayShape', ...
        'Active coordinate matrices must have identical sizes.');
end
end

function value = get_field_local(s, name, fallback)
if isfield(s, name)
    value = s.(name);
else
    value = fallback;
end
end

function R = rotation_z_local(angle_deg)
c = cosd(angle_deg);
s = sind(angle_deg);
R = [c, -s, 0; s, c, 0; 0, 0, 1];
end

function angle = wrap180_local(angle)
angle = mod(angle + 180, 360) - 180;
end
