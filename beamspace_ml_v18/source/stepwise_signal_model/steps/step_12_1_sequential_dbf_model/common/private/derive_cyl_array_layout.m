function layout = derive_cyl_array_layout(array_meta)
%DERIVE_CYL_ARRAY_LAYOUT Derive dimensions and permutations from arr_cyl data.

required_fields = {'XAct','YAct','ZAct'};
for idx = 1:numel(required_fields)
    if ~isfield(array_meta, required_fields{idx})
        error('derive_cyl_array_layout:MissingField', ...
            'array_meta.%s is required.', required_fields{idx});
    end
end

X = array_meta.XAct;
Y = array_meta.YAct;
Z = array_meta.ZAct;
if ~ismatrix(X) || ~isequal(size(X), size(Y), size(Z)) || isempty(X)
    error('derive_cyl_array_layout:InvalidCoordinateMatrices', ...
        'XAct, YAct, and ZAct must be non-empty matrices with identical sizes.');
end
[N_az, N_el] = size(X);
N_elem = N_az * N_el;

if isfield(array_meta, 'xActVec') && ~isequal(array_meta.xActVec(:), X(:))
    error('derive_cyl_array_layout:XVectorOrder', ...
        'array_meta.xActVec is not the MATLAB column-major vector of XAct.');
end
if isfield(array_meta, 'yActVec') && ~isequal(array_meta.yActVec(:), Y(:))
    error('derive_cyl_array_layout:YVectorOrder', ...
        'array_meta.yActVec is not the MATLAB column-major vector of YAct.');
end
if isfield(array_meta, 'zActVec') && ~isequal(array_meta.zActVec(:), Z(:))
    error('derive_cyl_array_layout:ZVectorOrder', ...
        'array_meta.zActVec is not the MATLAB column-major vector of ZAct.');
end

legacy_index_matrix = reshape(1:N_elem, N_az, N_el);
canonical_to_legacy_index = legacy_index_matrix.';
canonical_to_legacy_index = canonical_to_legacy_index(:);
legacy_to_canonical_index = zeros(N_elem, 1);
legacy_to_canonical_index(canonical_to_legacy_index) = (1:N_elem).';

layout = struct();
layout.N_az = N_az;
layout.N_el = N_el;
layout.N_elem = N_elem;
layout.legacy_matrix_shape = [N_az, N_el];
layout.canonical_matrix_shape = [N_el, N_az];
layout.legacy_order = 'azimuth_fastest_elevation_slowest_from_XAct_colon';
layout.canonical_order = 'elevation_fastest_azimuth_slowest_vec_Nel_by_Naz';
layout.canonical_to_legacy_index = canonical_to_legacy_index;
layout.legacy_to_canonical_index = legacy_to_canonical_index;
end
