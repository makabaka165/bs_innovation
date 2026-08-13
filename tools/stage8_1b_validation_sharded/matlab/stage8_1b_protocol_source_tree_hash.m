function digest = stage8_1b_protocol_source_tree_hash(repo_dir)
%STAGE8_1B_PROTOCOL_SOURCE_TREE_HASH Hash tracked tool blobs deterministically.

command = sprintf(['git -C "%s" ls-tree -r --full-tree HEAD -- ', ...
    'tools/stage8_1b_validation_sharded'], char(string(repo_dir)));
[status, output] = system(command);
if status ~= 0 || isempty(strtrim(output))
    error('stage8_1b_protocol_source_tree_hash:Git', ...
        'Unable to enumerate committed sharded-runner blobs.');
end
carriage_return = char(13);
line_feed = newline;
normalized = strrep(output, [carriage_return, line_feed], line_feed);
normalized = strrep(normalized, carriage_return, line_feed);
digest = stage8_stable_hash( ...
    'STAGE8_1B_PROTOCOL_SOURCE_TREE_V1', normalized);
end
