function [Ymat, info] = reshape_cyl_vector_to_matrix(yvec, array_meta)
%RESHAPE_CYL_VECTOR_TO_MATRIX Map arr_cyl vectors to [N_el,N_az,...].

layout = derive_cyl_array_layout(array_meta);
input_size = size(yvec);
if isvector(yvec)
    if numel(yvec) ~= layout.N_elem
        error('reshape_cyl_vector_to_matrix:ElementCount', ...
            'Vector length %d does not match array element count %d.', ...
            numel(yvec), layout.N_elem);
    end
    legacy_matrix = reshape(yvec(:), layout.N_az, layout.N_el);
    Ymat = permute(legacy_matrix, [2, 1]);
else
    if size(yvec, 1) ~= layout.N_elem
        error('reshape_cyl_vector_to_matrix:FirstDimension', ...
            'size(yvec,1) must equal %d.', layout.N_elem);
    end
    trailing_size = input_size(2:end);
    legacy_tensor = reshape(yvec, [layout.N_az, layout.N_el, trailing_size]);
    order = [2, 1, 3:(2 + numel(trailing_size))];
    Ymat = permute(legacy_tensor, order);
end

info = layout;
info.input_size = input_size;
info.output_size = size(Ymat);
info.mapping = 'canonical_vector=legacy_vector(canonical_to_legacy_index)';
end
