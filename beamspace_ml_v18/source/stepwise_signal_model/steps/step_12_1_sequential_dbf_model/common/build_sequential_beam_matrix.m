function [Wseq, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta)
%BUILD_SEQUENTIAL_BEAM_MATRIX Build canonical u_(c|b) kron v_b columns.

layout = derive_cyl_array_layout(array_meta);
if size(V, 1) ~= layout.N_el || isempty(V)
    error('build_sequential_beam_matrix:VShape', ...
        'V must have N_el=%d rows and at least one column.', layout.N_el);
end
B_el = size(V, 2);
if size(Uset, 1) ~= layout.N_az || size(Uset, 3) ~= B_el || isempty(Uset)
    error('build_sequential_beam_matrix:UsetShape', ...
        'Uset must have shape [N_az,B_az,B_el] = [%d,B_az,%d].', ...
        layout.N_az, B_el);
end
B_az = size(Uset, 2);
Wseq = complex(zeros(layout.N_elem, B_el * B_az));
el_channel_index = zeros(B_el * B_az, 1);
az_beam_index = zeros(B_el * B_az, 1);

for c = 1:B_az
    for b = 1:B_el
        column = b + (c - 1) * B_el;
        Wseq(:, column) = kron(Uset(:, c, b), V(:, b));
        el_channel_index(column) = b;
        az_beam_index(column) = c;
    end
end

beam_meta = layout;
beam_meta.phase_factor = 1;
beam_meta.B_el = B_el;
beam_meta.B_az = B_az;
beam_meta.B_total = B_el * B_az;
beam_meta.Wseq_size = size(Wseq);
beam_meta.column_order = 'el_channel_fastest_then_az_beam_matches_Zseq_colon';
beam_meta.el_channel_index = el_channel_index;
beam_meta.az_beam_index = az_beam_index;
beam_meta.element_vector_order = layout.canonical_order;
end
