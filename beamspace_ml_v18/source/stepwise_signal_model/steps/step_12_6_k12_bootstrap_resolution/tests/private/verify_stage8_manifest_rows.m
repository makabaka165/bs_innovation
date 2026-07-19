function result = verify_stage8_manifest_rows(root_dir, relative_path, ...
    byte_count, expected_hash)
%VERIFY_STAGE8_MANIFEST_ROWS Verify registered file size and SHA-256.

count = numel(relative_path);
missing = false(count, 1);
size_mismatch = false(count, 1);
hash_mismatch = false(count, 1);
for index = 1:count
    path_now = fullfile(root_dir, strrep(char(relative_path(index)), '/', filesep));
    if exist(path_now, 'file') ~= 2
        missing(index) = true;
        continue;
    end
    info = dir(path_now);
    size_mismatch(index) = info.bytes ~= byte_count(index);
    hash_mismatch(index) = ~strcmpi(stage8_sha256_file(path_now), ...
        char(expected_hash(index)));
end
pass_flag = ~(missing | size_mismatch | hash_mismatch);
result = table(string(relative_path(:)), missing, size_mismatch, ...
    hash_mismatch, pass_flag, 'VariableNames', {'relative_path', ...
    'missing_flag','size_mismatch_flag','hash_mismatch_flag','pass_flag'});
end
