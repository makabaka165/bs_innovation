function [result_table, context] = verify_step11_frozen_results(package_dir)
%VERIFY_STEP11_FROZEN_RESULTS Recheck official Step11 result hashes.

manifest_path = fullfile(package_dir, 'FILE_SHA256.csv');
manifest = readtable(manifest_path, 'TextType', 'string');
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
    file_info = dir(path_now);
    size_mismatch(index) = file_info.bytes ~= frozen.Bytes(index);
    hash_mismatch(index) = ~strcmpi( ...
        sha256_file_local(path_now), char(frozen.SHA256(index)));
end
pass_flag = ~(missing | size_mismatch | hash_mismatch);
result_table = table(frozen.RelativePath, frozen.Bytes, missing, ...
    size_mismatch, hash_mismatch, pass_flag, 'VariableNames', ...
    {'relative_path','expected_bytes','missing_flag', ...
    'size_mismatch_flag','hash_mismatch_flag','pass_flag'});
assert(height(frozen) == 351 && all(pass_flag), ...
    'verify_step11_frozen_results:Failed', ...
    'A frozen Step11 result differs from the official manifest.');
context = struct('file_count', height(frozen), ...
    'byte_count', sum(frozen.Bytes), ...
    'hash_mismatch_count', nnz(hash_mismatch), 'pass_flag', all(pass_flag));
end

function digest = sha256_file_local(path_now)
bytes = java.nio.file.Files.readAllBytes( ...
    java.nio.file.Paths.get(path_now, javaArray('java.lang.String', 0)));
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
digest_bytes = typecast(md.digest(), 'uint8');
digest = lower(reshape(dec2hex(digest_bytes, 2).', 1, []));
end
