function [result_table, info] = test_noise_covariance_after_dbf( ...
    el_beam_deg, az_beam_deg, el_condition_deg, cfg)
%TEST_NOISE_COVARIANCE_AFTER_DBF Validate Wseq'Wseq by white-noise Monte Carlo.

rng(120103, 'twister');
N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
[~, V] = form_elevation_dbf_cube(complex(zeros(N_el, N_az)), el_beam_deg, cfg);
[~, Uset] = form_azimuth_dbf_cube( ...
    complex(zeros(numel(el_beam_deg), N_az)), ...
    az_beam_deg, el_condition_deg, cfg);
[Wseq, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta);
C_theory = Wseq' * Wseq;
B_total = size(Wseq, 2);

checkpoints = [1000; 5000; 20000];
registered_threshold = [0.12; 0.07; 0.04];
chunk_size = 500;
sum_z = complex(zeros(B_total, 1));
sum_zz = complex(zeros(B_total, B_total));
relative_covariance_error = zeros(numel(checkpoints), 1);
max_abs_covariance_error = zeros(numel(checkpoints), 1);
trace_ratio = zeros(numel(checkpoints), 1);
pass_flag = false(numel(checkpoints), 1);
phase_factor = ones(numel(checkpoints), 1);
max_sequential_direct_relative_error = 0;
checkpoint_index = 1;

for start_idx = 1:chunk_size:checkpoints(end)
    count = min(chunk_size, checkpoints(end) - start_idx + 1);
    noise_canonical = complex(randn(N_el * N_az, count), ...
        randn(N_el * N_az, count)) / sqrt(2);
    Ynoise = reshape(noise_canonical, N_el, N_az, 1, count);
    Zel = form_elevation_dbf_cube(Ynoise, el_beam_deg, cfg);
    Zseq = form_azimuth_dbf_cube(Zel, az_beam_deg, el_condition_deg, cfg);
    Z = reshape(Zseq, B_total, count);
    Zdirect = Wseq' * noise_canonical;
    direct_error = norm(Z - Zdirect, 'fro') / max(norm(Zdirect, 'fro'), eps);
    max_sequential_direct_relative_error = max( ...
        max_sequential_direct_relative_error, direct_error);
    sum_z = sum_z + sum(Z, 2);
    sum_zz = sum_zz + Z * Z';
    n_done = start_idx + count - 1;
    if n_done == checkpoints(checkpoint_index)
        mean_z = sum_z / n_done;
        C_sample = sum_zz / n_done - mean_z * mean_z';
        delta = C_sample - C_theory;
        relative_covariance_error(checkpoint_index) = norm(delta, 'fro') / ...
            max(norm(C_theory, 'fro'), eps);
        max_abs_covariance_error(checkpoint_index) = max(abs(delta(:)));
        trace_ratio(checkpoint_index) = real(trace(C_sample) / trace(C_theory));
        pass_flag(checkpoint_index) = relative_covariance_error(checkpoint_index) < ...
            registered_threshold(checkpoint_index);
        checkpoint_index = checkpoint_index + 1;
        if checkpoint_index > numel(checkpoints)
            break;
        end
    end
end

convergence_flag = relative_covariance_error(end) < relative_covariance_error(1);
pass_flag(end) = pass_flag(end) && convergence_flag && ...
    max_sequential_direct_relative_error < 1e-12;
num_beams = repmat(B_total, numel(checkpoints), 1);
result_table = table(checkpoints, num_beams, relative_covariance_error, ...
    max_abs_covariance_error, trace_ratio, registered_threshold, ...
    pass_flag, phase_factor, 'VariableNames', ...
    {'n_samples','num_beams','relative_covariance_error', ...
     'max_abs_covariance_error','trace_ratio','registered_threshold', ...
     'pass_flag','phase_factor'});
assert(all(pass_flag), 'test_noise_covariance_after_dbf:Failed', ...
    'The white-noise covariance validation failed its registered gates.');

info = struct();
info.phase_factor = 1;
info.Wseq = Wseq;
info.C_theory = C_theory;
info.beam_meta = beam_meta;
info.chunk_size = chunk_size;
info.num_samples = checkpoints(end);
info.max_sequential_direct_relative_error = max_sequential_direct_relative_error;
info.convergence_flag = convergence_flag;
end
