function [result_table, context] = verify_step11_frozen_results(package_dir)
%VERIFY_STEP11_FROZEN_RESULTS Recheck official Step11 result hashes.

manifest = readtable(fullfile(package_dir, 'FILE_SHA256.csv'), ...
    'TextType', 'string');
selected = startsWith(manifest.RelativePath, ...
    "source/stepwise_signal_model/steps/step_11_") & ...
    contains(manifest.RelativePath, "/results_step11_");
frozen = manifest(selected, :);
missing = false(height(frozen), 1);
size_mismatch = false(height(frozen), 1);
hash_mismatch = false(height(frozen), 1);
for index = 1:height(frozen)
    path_now = fullfile(package_dir, ...
        strrep(char(frozen.RelativePath(index)), '/', filesep));
    if exist(path_now, 'file') ~= 2
        missing(index) = true;
        continue;
    end
    info = dir(path_now);
    size_mismatch(index) = info.bytes ~= frozen.Bytes(index);
    hash_mismatch(index) = ~strcmpi(stage7_1_sha256_file(path_now), ...
        char(frozen.SHA256(index)));
end
pass_flag = ~(missing | size_mismatch | hash_mismatch);
result_table = table(frozen.RelativePath, missing, size_mismatch, ...
    hash_mismatch, pass_flag, 'VariableNames', {'relative_path', ...
    'missing_flag','size_mismatch_flag','hash_mismatch_flag','pass_flag'});
assert(height(frozen) == 351 && all(pass_flag), ...
    'verify_step11_frozen_results:Failed', ...
    'A frozen Step11 result changed.');
context = struct('file_count', height(frozen), ...
    'hash_mismatch_count', nnz(hash_mismatch), 'pass_flag', all(pass_flag));
end
