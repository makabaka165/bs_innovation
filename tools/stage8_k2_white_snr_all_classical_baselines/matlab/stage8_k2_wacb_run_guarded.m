function output = stage8_k2_wacb_run_guarded(repo_dir, runtime_root)
%STAGE8_K2_WACB_RUN_GUARDED Publish a hard-stop marker on runner failure.

try
    output = stage8_k2_wacb_run(repo_dir, runtime_root);
catch exception
    write_failure_local(runtime_root, 'RUNNER', exception);
    rethrow(exception);
end
end

function write_failure_local(runtime_root, role, exception)
status_dir = fullfile(runtime_root, 'status');
if ~isfolder(status_dir), mkdir(status_dir); end
failure = struct('protocol', ...
    'STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_V2', ...
    'role', role, 'identifier', exception.identifier, ...
    'message', exception.message, ...
    'report', getReport(exception, 'extended', 'hyperlinks', 'off'), ...
    'failed_utc', char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''')));
stage8_k2_wacb_write_json_atomic(fullfile(status_dir, ...
    'hard_stop.json'), failure);
end
