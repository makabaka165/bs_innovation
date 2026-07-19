function manifest = stage8_git_blob_manifest(repo_dir, relative_paths)
%STAGE8_GIT_BLOB_MANIFEST Read sorted Git index mode/blob/path identities.

relative_paths = sort(unique(string(relative_paths(:))));
empty_row = struct('git_mode', "", 'git_blob_hash', "", ...
    'relative_path', "");
rows = repmat(empty_row, numel(relative_paths), 1);
row_count = 0;
for path_index = 1:numel(relative_paths)
    command = sprintf('git -C "%s" ls-files --stage -- "%s"', ...
        repo_dir, char(relative_paths(path_index)));
    [status, output] = system(command);
    if status ~= 0
        error('stage8_git_blob_manifest:Git', ...
            'Unable to inspect Git identity for %s.', relative_paths(path_index));
    end
    lines = splitlines(string(regexprep(output, '[\r\n]+$', '')));
    lines(lines == "") = [];
    for line_index = 1:numel(lines)
        token = regexp(lines(line_index), ...
            '^(\d+)\s+([0-9a-f]+)\s+(\d+)\t(.+)$', 'tokens', 'once');
        if isempty(token) || ~strcmp(token{3}, '0')
            error('stage8_git_blob_manifest:Parse', ...
                'Unexpected or conflicted Git index entry: %s.', lines(line_index));
        end
        row_count = row_count + 1;
        rows(row_count) = struct('git_mode', string(token{1}), ...
            'git_blob_hash', string(token{2}), ...
            'relative_path', string(strrep(token{4}, '\', '/')));
    end
end
if row_count == 0
    manifest = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        'VariableNames', {'git_mode','git_blob_hash','relative_path'});
    return;
end
manifest = struct2table(rows(1:row_count));
manifest = sortrows(unique(manifest, 'rows'), 'relative_path');
end
