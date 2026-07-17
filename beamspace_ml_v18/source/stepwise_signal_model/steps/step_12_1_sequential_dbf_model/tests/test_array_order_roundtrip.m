function result_table = test_array_order_roundtrip(cfg)
%TEST_ARRAY_ORDER_ROUNDTRIP Validate the audited legacy/canonical mapping.

rng(120101, 'twister');
array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
N_elem = array_meta.nAct;
inputs = {complex(randn(N_elem, 1), randn(N_elem, 1)), ...
          complex(randn(N_elem, 3, 4), randn(N_elem, 3, 4))};
case_name = ["random_complex_vector"; "random_complex_range_snapshot_cube"];
relative_roundtrip_error = zeros(2, 1);
permutation_relative_error = zeros(2, 1);
coordinate_mapping_error = zeros(2, 1);
pass_flag = false(2, 1);
phase_factor = ones(2, 1);

expected_X = array_meta.XAct.';
expected_Y = array_meta.YAct.';
expected_Z = array_meta.ZAct.';
[Xcanonical, mapping_info] = reshape_cyl_vector_to_matrix(array_meta.xActVec, array_meta);
Ycanonical = reshape_cyl_vector_to_matrix(array_meta.yActVec, array_meta);
Zcanonical = reshape_cyl_vector_to_matrix(array_meta.zActVec, array_meta);
coord_error = max([max(abs(Xcanonical(:) - expected_X(:))), ...
                   max(abs(Ycanonical(:) - expected_Y(:))), ...
                   max(abs(Zcanonical(:) - expected_Z(:)))]);

for idx = 1:numel(inputs)
    original = inputs{idx};
    canonical = reshape_cyl_vector_to_matrix(original, array_meta);
    recovered = reshape_cyl_matrix_to_vector(canonical, array_meta);
    relative_roundtrip_error(idx) = norm(recovered(:) - original(:)) / max(norm(original(:)), eps);
    legacy_first = reshape(original, N_elem, []);
    canonical_first = reshape(canonical, N_elem, []);
    expected_canonical = legacy_first(mapping_info.canonical_to_legacy_index, :);
    permutation_relative_error(idx) = norm(canonical_first - expected_canonical, 'fro') / ...
        max(norm(expected_canonical, 'fro'), eps);
    coordinate_mapping_error(idx) = coord_error;
    pass_flag(idx) = relative_roundtrip_error(idx) < 1e-14 && ...
        permutation_relative_error(idx) < 1e-14 && coord_error < 1e-14;
end

input_size_text = [string(size_text_local(size(inputs{1}))); ...
                   string(size_text_local(size(inputs{2})))];
result_table = table(case_name, input_size_text, relative_roundtrip_error, ...
    permutation_relative_error, coordinate_mapping_error, pass_flag, phase_factor);
assert(all(pass_flag), 'test_array_order_roundtrip:Failed', ...
    'The legacy/canonical array-order roundtrip failed.');
end

function text = size_text_local(sz)
text = sprintf('%dx', sz);
text(end) = [];
end
