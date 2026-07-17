function [yvec, info] = reshape_cyl_matrix_to_vector(Ymat, array_meta)
%RESHAPE_CYL_MATRIX_TO_VECTOR Map [N_el,N_az,...] back to arr_cyl order.

layout = derive_cyl_array_layout(array_meta);
input_size = size(Ymat);
if size(Ymat, 1) ~= layout.N_el || size(Ymat, 2) ~= layout.N_az
    error('reshape_cyl_matrix_to_vector:LeadingDimensions', ...
        'Ymat must start with [%d,%d].', layout.N_el, layout.N_az);
end

if ismatrix(Ymat)
    legacy_matrix = permute(Ymat, [2, 1]);
    yvec = legacy_matrix(:);
else
    trailing_size = input_size(3:end);
    order = [2, 1, 3:(2 + numel(trailing_size))];
    legacy_tensor = permute(Ymat, order);
    yvec = reshape(legacy_tensor, [layout.N_elem, trailing_size]);
end

info = layout;
info.input_size = input_size;
info.output_size = size(yvec);
info.mapping = 'legacy_vector=canonical_vector(legacy_to_canonical_index)';
end
