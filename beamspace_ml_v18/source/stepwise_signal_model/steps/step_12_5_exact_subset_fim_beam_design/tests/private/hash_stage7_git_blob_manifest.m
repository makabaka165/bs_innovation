function [manifest, tree_hash] = hash_stage7_git_blob_manifest( ...
    manifest, scope_id)
%HASH_STAGE7_GIT_BLOB_MANIFEST Hash sorted Git mode/blob/path records.

if isstring(scope_id), scope_id = char(scope_id); end
if ~(ischar(scope_id) && isrow(scope_id) && ~isempty(scope_id))
    error('hash_stage7_git_blob_manifest:Scope', ...
        'scope_id must be nonempty scalar text.');
end
required = {'relative_path','git_mode','git_blob_hash'};
if ~(istable(manifest) && ...
        all(ismember(required, manifest.Properties.VariableNames)))
    error('hash_stage7_git_blob_manifest:Manifest', ...
        'Manifest identity columns are missing.');
end

paths = replace(string(manifest.relative_path), '\', '/');
modes = lower(string(manifest.git_mode));
blobs = lower(string(manifest.git_blob_hash));
if isempty(paths) || any(ismissing(paths) | strlength(paths) == 0 | ...
        ismissing(modes) | ismissing(blobs))
    error('hash_stage7_git_blob_manifest:MissingValue', ...
        'Manifest identity values must be present.');
end
if numel(unique(paths)) ~= numel(paths)
    error('hash_stage7_git_blob_manifest:DuplicatePath', ...
        'Manifest paths must be unique.');
end
for index = 1:numel(paths)
    validate_path_local(paths(index));
    if isempty(regexp(char(modes(index)), '^[0-9]{6}$', 'once'))
        error('hash_stage7_git_blob_manifest:Mode', ...
            'Invalid Git mode for %s.', paths(index));
    end
    if isempty(regexp(char(blobs(index)), '^[0-9a-f]{40,64}$', 'once'))
        error('hash_stage7_git_blob_manifest:Blob', ...
            'Invalid Git blob id for %s.', paths(index));
    end
end

[paths, order] = sort(paths);
modes = modes(order);
blobs = blobs(order);
source_scope = repmat(string(scope_id), numel(paths), 1);
manifest_order = (1:numel(paths)).';
manifest = table(paths, modes, blobs, source_scope, manifest_order, ...
    'VariableNames', {'relative_path','git_mode','git_blob_hash', ...
    'source_scope','manifest_order'});

payload = uint8([]);
for index = 1:height(manifest)
    payload = [payload, utf8_local(manifest.git_mode(index)), uint8(0), ...
        utf8_local(manifest.git_blob_hash(index)), uint8(0), ...
        utf8_local(manifest.relative_path(index))]; %#ok<AGROW>
end
tree_hash = sha256_local(payload);
end

function validate_path_local(path_now)
text = char(path_now);
if isempty(text) || startsWith(text, '/') || ...
        ~isempty(regexp(text, '^[A-Za-z]:', 'once')) || ...
        ~isempty(regexp(text, '[\t\r\n"]', 'once')) || ...
        any(strcmp(split(string(text), '/'), '..'))
    error('hash_stage7_git_blob_manifest:Path', ...
        'Manifest paths must be safe repository-relative paths.');
end
end

function bytes = utf8_local(value)
bytes = uint8(unicode2native(char(value), 'UTF-8'));
end

function digest = sha256_local(payload)
sha = System.Security.Cryptography.SHA256.Create();
cleanup = onCleanup(@() sha.Dispose());
bytes = uint8(sha.ComputeHash(payload));
digest = lower(reshape(dec2hex(bytes, 2).', 1, []));
clear cleanup
end
