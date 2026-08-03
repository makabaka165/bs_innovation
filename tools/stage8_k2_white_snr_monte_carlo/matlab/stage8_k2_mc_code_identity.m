function identity = stage8_k2_mc_code_identity(repo_dir)
%STAGE8_K2_MC_CODE_IDENTITY Bind all files in the isolated tool tree.

tool_root = fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_monte_carlo');
items = dir(fullfile(tool_root, '**', '*'));
items = items(~[items.isdir]);
relative = strings(numel(items), 1);
hashes = strings(numel(items), 1);
prefix = [char(java.io.File(tool_root).getCanonicalPath()), filesep];
for index = 1:numel(items)
    path_now = fullfile(items(index).folder, items(index).name);
    canonical = char(java.io.File(path_now).getCanonicalPath());
    relative(index) = string(strrep( ...
        canonical(numel(prefix) + 1:end), filesep, '/'));
    hashes(index) = string(stage8_k2_mc_file_sha256(canonical));
end
[relative, order] = sort(relative);
hashes = hashes(order);
identity = struct('file_count', numel(relative), ...
    'relative_paths', relative, 'sha256', hashes, ...
    'tree_hash', stage8_k2_mc_stable_hash( ...
    'TOOL_SOURCE_TREE', relative, hashes));
end
