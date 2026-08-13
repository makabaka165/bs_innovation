function digest = stage8_compact_source_hash(repo_dir)
%STAGE8_COMPACT_SOURCE_HASH Hash committed compact-tool blobs.

command = sprintf(['git -C "%s" ls-tree -r --full-tree HEAD -- ', ...
    'tools/stage8_compact_diagnostic'], char(string(repo_dir)));
[status, output] = system(command);
if status ~= 0 || isempty(strtrim(output))
    error('stage8_compact_source_hash:Git', ...
        'Unable to enumerate committed compact diagnostic blobs.');
end
output = strrep(output, [char(13), newline], newline);
output = strrep(output, char(13), newline);
digest = stage8_stable_hash( ...
    'STAGE8_COMPACT_PROTOCOL_SOURCE_TREE_V2', output);
end
