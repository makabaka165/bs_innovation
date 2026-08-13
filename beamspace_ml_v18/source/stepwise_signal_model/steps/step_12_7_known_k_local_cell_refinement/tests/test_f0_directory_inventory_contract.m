function audit = test_f0_directory_inventory_contract()
%TEST_F0_DIRECTORY_INVENTORY_CONTRACT Count only real direct entries.

root = [tempname, '_stage8_f0_inventory'];
assert(~isfolder(root) && mkdir(root));
cleanup = onCleanup(@() cleanup_local(root));

empty = stage8_core_v2_2_directory_inventory(root);
assert(empty.file_count == 0 && empty.directory_count == 0);
assert(isempty(empty.file_names) && isempty(empty.directory_names));

file_path = fullfile(root, 'sample.mat.tmp');
write_sample_local(file_path);
one_file = stage8_core_v2_2_directory_inventory(root);
assert(one_file.file_count == 1 && one_file.directory_count == 0);
assert(isequal(one_file.file_names, "sample.mat.tmp"));
delete(file_path);

directory_path = fullfile(root, 'unexpected');
assert(mkdir(directory_path));
one_directory = stage8_core_v2_2_directory_inventory(root);
assert(one_directory.file_count == 0 && ...
    one_directory.directory_count == 1);
assert(isequal(one_directory.directory_names, "unexpected"));

write_sample_local(file_path);
mixed = stage8_core_v2_2_directory_inventory(root);
assert(mixed.file_count == 1 && mixed.directory_count == 1);
assert(isequal(mixed.file_names, "sample.mat.tmp"));
assert(isequal(mixed.directory_names, "unexpected"));

missing_thrown = false;
try
    stage8_core_v2_2_directory_inventory(fullfile(root, 'missing'));
catch
    missing_thrown = true;
end
assert(missing_thrown);
audit = struct('pass', true, ...
    'status', 'F0_DIRECTORY_INVENTORY_CONTRACT_PASS', ...
    'empty_directory_pass', true, 'one_file_pass', true, ...
    'one_directory_pass', true, 'mixed_entries_pass', true);
clear cleanup
end

function write_sample_local(path_now)
fid = fopen(path_now, 'w');
if fid < 0
    error('test_f0_directory_inventory_contract:Write', ...
        'Unable to create the temporary sample file.');
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, uint8([1, 2, 3]), 'uint8');
clear cleanup
end

function cleanup_local(root)
if isfolder(root)
    rmdir(root, 's');
end
end
