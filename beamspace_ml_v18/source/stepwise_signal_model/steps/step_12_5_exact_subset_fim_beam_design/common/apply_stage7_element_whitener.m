function whitened = apply_stage7_element_whitener(matrix, noise, cfg)
%APPLY_STAGE7_ELEMENT_WHITENER Apply the exact separable Cholesky whitener.

N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
if size(matrix, 1) ~= N_el * N_az
    error('apply_stage7_element_whitener:Shape', ...
        'matrix must contain one row per canonical array element.');
end
whitened = complex(zeros(size(matrix)));
for column_index = 1:size(matrix, 2)
    page = reshape(matrix(:, column_index), N_el, N_az);
    page = noise.L_el \ page / noise.L_az.';
    whitened(:, column_index) = page(:);
end
end
