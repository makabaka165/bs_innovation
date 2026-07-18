function F_schur = effective_deterministic_fim_schur_reference( ...
    G, dG, S, sigma2)
%EFFECTIVE_DETERMINISTIC_FIM_SCHUR_REFERENCE Small explicit real-FIM fixture.

K = size(G, 2);
L = size(S, 2);
parameter_count = 2 * K;
observation_count = size(G, 1) * L;
J_angle = complex(zeros(observation_count, parameter_count));
for target_index = 1:K
    rows = {dG.azimuth(:, target_index), dG.elevation(:, target_index)};
    for dimension = 1:2
        parameter_index = 2 * target_index - 2 + dimension;
        H = rows{dimension} * S(target_index, :);
        J_angle(:, parameter_index) = H(:);
    end
end
J_nuisance = complex(zeros(observation_count, 2 * K * L));
for snapshot_index = 1:L
    observation_rows = (snapshot_index - 1) * size(G, 1) + ...
        (1:size(G, 1));
    nuisance_columns = (snapshot_index - 1) * 2 * K + (1:2*K);
    J_nuisance(observation_rows, nuisance_columns) = [G, 1j * G];
end
J = [J_angle, J_nuisance];
F_full = (2 / sigma2) * real(J' * J);
F_aa = F_full(1:parameter_count, 1:parameter_count);
F_ab = F_full(1:parameter_count, parameter_count + 1:end);
F_bb = F_full(parameter_count + 1:end, parameter_count + 1:end);
F_schur = F_aa - F_ab * pinv(F_bb) * F_ab.';
F_schur = 0.5 * (F_schur + F_schur.');
end
