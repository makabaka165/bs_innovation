function [manifest, digest] = stage8_k2_tecs_code_manifest(repo_dir, scope)
%STAGE8_K2_TECS_CODE_MANIFEST Hash exact prototype or complete TECS sources.

if nargin < 2 || isempty(scope), scope = 'ALL'; end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
scope = upper(char(string(scope)));
root = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_exact_cache_stack');
switch scope
    case 'ALL'
        files = dir(fullfile(root, '**', '*.m'));
        absolute = arrayfun(@(item) fullfile(item.folder, item.name), ...
            files, 'UniformOutput', false);
        role = repmat("TECS_SOURCE_OR_TEST", numel(absolute), 1);
        domain = 'TECS_COMPLETE_CODE_MANIFEST_V1';
    case 'COMPONENT_CORE'
        names = { ...
            'stage8_k2_tecs_serialize.m'; ...
            'stage8_k2_tecs_sha256.m'; ...
            'stage8_k2_tecs_cache_session.m'; ...
            'stage8_k2_tecs_promote_c1_artifact.m'; ...
            'stage8_k2_tecs_build_provider.m'; ...
            'stage8_k2_tecs_provider_pair.m'};
        absolute = cellfun(@(name) fullfile(root, 'matlab', name), ...
            names, 'UniformOutput', false);
        role = ["CANONICAL_SERIALIZER";"DOMAIN_HASH";"SESSION_CORE"; ...
            "C1_ARTIFACT_PROMOTION";"EXPLICIT_PROVIDER"; ...
            "C1_LOOKUP_FALLBACK_DISPATCH"];
        domain = 'TECS_COMPONENT_CORE_MANIFEST_V1';
    otherwise
        error('stage8_k2_tecs_code_manifest:Scope', ...
            'Unsupported code-manifest scope: %s.', scope);
end
if isempty(absolute) || any(~cellfun(@isfile, absolute))
    error('stage8_k2_tecs_code_manifest:Missing', ...
        'The %s code manifest contains a missing source.', scope);
end
relative_path = strings(numel(absolute), 1);
file_sha256 = strings(numel(absolute), 1);
for index = 1:numel(absolute)
    canonical = char(java.io.File(absolute{index}).getCanonicalPath());
    relative_path(index) = string(strrep( ...
        erase(canonical, [repo_dir, filesep]), '\', '/'));
    file_sha256(index) = string(stage8_k2_tecs_sha256_file(canonical));
end
[relative_path, order] = sort(relative_path);
file_sha256 = file_sha256(order);
role = role(order);
manifest = table(relative_path, role, file_sha256);
digest = stage8_k2_tcc_stable_hash(domain, manifest);
end
