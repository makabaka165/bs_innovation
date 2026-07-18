function table_out = benchmark_stage7_online_dbf_runtime(context)
%BENCHMARK_STAGE7_ONLINE_DBF_RUNTIME Measure count-profile DBF runtime.

settings = context.plan.cost;
previous_rng = rng;
rng_cleanup = onCleanup(@() rng(previous_rng));
rng(settings.online_benchmark_seed, 'twister');
cfg = context.cfg;
pool = context.plan.pool;
sample_count = settings.online_benchmark_batch_samples;
repeat_count = settings.online_benchmark_repeats;
warmup_count = settings.online_benchmark_warmup_count;
X = complex(randn(cfg.arr.Nel, cfg.beam.subNaz, sample_count), ...
    randn(cfg.arr.Nel, cfg.beam.subNaz, sample_count)) / sqrt(2);
X_matrix = reshape(X, cfg.arr.Nel, cfg.beam.subNaz * sample_count);

profile_id = strings(25, 1);
B_e = zeros(25, 1);
B_a = zeros(25, 1);
B_out = zeros(25, 1);
measured_online_dbf_runtime = zeros(25, 1);
runtime_mean = zeros(25, 1);
runtime_std = zeros(25, 1);
row_index = 0;
for elevation_count = 1:5
    for azimuth_count = 1:5
        row_index = row_index + 1;
        elevation_indices = 1:elevation_count;
        azimuth_indices = 1:azimuth_count;
        for warmup_index = 1:warmup_count
            online_dbf_local(X_matrix, pool.V, pool.Uset, ...
                elevation_indices, azimuth_indices, cfg.beam.subNaz, ...
                sample_count);
        end
        times = zeros(repeat_count, 1);
        for repeat_index = 1:repeat_count
            start_tic = tic;
            Z = online_dbf_local(X_matrix, pool.V, pool.Uset, ...
                elevation_indices, azimuth_indices, cfg.beam.subNaz, ...
                sample_count); %#ok<NASGU>
            times(repeat_index) = toc(start_tic) / sample_count;
        end
        profile_id(row_index) = sprintf('BE%d_BA%d', ...
            elevation_count, azimuth_count);
        B_e(row_index) = elevation_count;
        B_a(row_index) = azimuth_count;
        B_out(row_index) = elevation_count * azimuth_count;
        measured_online_dbf_runtime(row_index) = median(times);
        runtime_mean(row_index) = mean(times);
        runtime_std(row_index) = std(times);
    end
end
batch_samples = repmat(sample_count, 25, 1);
repeats = repmat(repeat_count, 25, 1);
warmup_repeats = repmat(warmup_count, 25, 1);
benchmark_seed = repmat(settings.online_benchmark_seed, 25, 1);
status = repmat("POST_FREEZE_DIAGNOSTIC_NOT_USED_FOR_SELECTION", 25, 1);
table_out = table(profile_id, B_e, B_a, B_out, ...
    measured_online_dbf_runtime, runtime_mean, runtime_std, ...
    batch_samples, repeats, warmup_repeats, benchmark_seed, status);
clear rng_cleanup
end

function Z = online_dbf_local(X_matrix, V, Uset, elevation_indices, ...
    azimuth_indices, N_az, sample_count)
B_e = numel(elevation_indices);
B_a = numel(azimuth_indices);
elevation_output = reshape(V(:, elevation_indices)' * X_matrix, ...
    B_e, N_az, sample_count);
Z = complex(zeros(B_a, B_e, sample_count));
for elevation_index = 1:B_e
    azimuth_input = reshape(elevation_output(elevation_index, :, :), ...
        N_az, sample_count);
    Z(:, elevation_index, :) = reshape( ...
        Uset(:, azimuth_indices, elevation_indices(elevation_index))' * ...
        azimuth_input, B_a, 1, sample_count);
end
end
