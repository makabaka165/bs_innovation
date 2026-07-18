function snapshot = capture_stage6_evidence_snapshot( ...
    step_dir, destination_dir, registry, opts)
%CAPTURE_STAGE6_EVIDENCE_SNAPSHOT Copy generated artifacts outside the step.

if nargin < 4 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
if isstring(step_dir), step_dir = char(step_dir); end
if isstring(destination_dir), destination_dir = char(destination_dir); end
if ~(ischar(step_dir) && isrow(step_dir) && exist(step_dir, 'dir') == 7 && ...
        ischar(destination_dir) && isrow(destination_dir) && ...
        ~isempty(destination_dir) && istable(registry))
    error('capture_stage6_evidence_snapshot:Inputs', ...
        'An existing step, destination and artifact registry are required.');
end
step_root = canonical_path_local(step_dir);
destination_root = canonical_path_local(destination_dir);
if path_is_within_local(destination_root, step_root)
    error('capture_stage6_evidence_snapshot:DestinationInsideStep', ...
        'The snapshot destination must be outside source/results/figures.');
end
repo_root = git_root_local(step_root);
if ~isempty(repo_root) && path_is_within_local(destination_root, repo_root)
    error('capture_stage6_evidence_snapshot:DestinationInsideRepository', ...
        'The snapshot destination must remain outside the Git repository.');
end
temp_root = canonical_path_local(tempdir);
if ~path_is_within_local(destination_root, temp_root) && ...
        ~opts.allow_non_temp_destination
    error('capture_stage6_evidence_snapshot:DestinationNotTemporary', ...
        'Non-temporary destinations require explicit authorization in opts.');
end
if exist(destination_root, 'dir') == 7
    entries = dir(destination_root);
    entries = entries(~ismember({entries.name}, {'.','..'}));
    if ~isempty(entries)
        error('capture_stage6_evidence_snapshot:DestinationNotEmpty', ...
            'The snapshot destination must be absent or empty.');
    end
else
    mkdir(destination_root);
end

copied_artifact_count = 0;
for index = 1:height(registry)
    relative = validate_relative_path_local(registry.relative_path(index));
    source = fullfile(step_root, char(relative));
    if exist(source, 'file') ~= 2, continue; end
    destination = fullfile(destination_root, char(relative));
    parent = fileparts(destination);
    if exist(parent, 'dir') ~= 7, mkdir(parent); end
    [copied, message] = copyfile(source, destination, 'f');
    if ~copied
        error('capture_stage6_evidence_snapshot:Copy', ...
            'Unable to copy %s: %s', relative, message);
    end
    copied_artifact_count = copied_artifact_count + 1;
end
[manifest, bundle] = build_stage6_evidence_manifest( ...
    destination_root, registry, struct('validation_scope', "CORE_RUNNER", ...
    'allow_missing_self_referential_artifacts', true));
snapshot = struct('destination_dir', string(destination_root), ...
    'copied_artifact_count', copied_artifact_count, ...
    'missing_registry_artifact_count', nnz(~manifest.file_exists_flag), ...
    'manifest', manifest, 'bundle', bundle, ...
    'pass_flag', all(manifest.pass_flag) && all(bundle.pass_flag));
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('capture_stage6_evidence_snapshot:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'allow_non_temp_destination'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('capture_stage6_evidence_snapshot:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'allow_non_temp_destination')
    opts.allow_non_temp_destination = false;
end
if ~(islogical(opts.allow_non_temp_destination) && ...
        isscalar(opts.allow_non_temp_destination))
    error('capture_stage6_evidence_snapshot:DestinationOption', ...
        'allow_non_temp_destination must be logical.');
end
end

function path_now = canonical_path_local(path_now)
path_now = char(java.io.File(path_now).getCanonicalPath());
end

function flag = path_is_within_local(path_now, root)
path_now = lower(path_now);
root = lower(root);
flag = strcmp(path_now, root) || startsWith(path_now, [root, filesep]);
end

function repo_root = git_root_local(path_now)
repo_root = '';
if contains(path_now, '"') || contains(path_now, newline)
    return;
end
[status, output] = system(sprintf( ...
    'git -C "%s" rev-parse --show-toplevel', path_now));
if status == 0
    repo_root = canonical_path_local(strtrim(output));
end
end

function relative = validate_relative_path_local(relative)
relative = replace(string(relative), '\', '/');
if ismissing(relative) || strlength(relative) == 0 || ...
        startsWith(relative, '/') || ...
        ~isempty(regexp(char(relative), '^[A-Za-z]:', 'once')) || ...
        any(split(relative, '/') == "..")
    error('capture_stage6_evidence_snapshot:Path', ...
        'Registry paths must remain below the snapshot root.');
end
end
