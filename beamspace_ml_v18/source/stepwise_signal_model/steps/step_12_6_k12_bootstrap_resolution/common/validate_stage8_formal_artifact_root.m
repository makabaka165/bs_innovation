function artifact_root = validate_stage8_formal_artifact_root( ...
    repo_dir, artifact_root, lifecycle, opts)
%VALIDATE_STAGE8_FORMAL_ARTIFACT_ROOT Enforce the registered evidence root.

if nargin < 4 || isempty(opts), opts = struct(); end
if ~(isstruct(opts) && isscalar(opts))
    error('validate_stage8_formal_artifact_root:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'require_empty_lifecycle'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('validate_stage8_formal_artifact_root:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'require_empty_lifecycle')
    opts.require_empty_lifecycle = false;
end
expected = fullfile(char(repo_dir), 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
expected = canonical_path_local(expected);
artifact_root = canonical_path_local(artifact_root);
if ~strcmpi(artifact_root, expected)
    error(['validate_stage8_formal_artifact_root:', ...
        'RegisteredRootRequired'], ...
        'Formal Stage8.1 evidence must use the registered Stage8 root.');
end
lifecycle = upper(string(lifecycle));
if lifecycle == "CALIBRATION"
    folder = fullfile(artifact_root, 'calibration');
elseif lifecycle == "VALIDATION"
    folder = fullfile(artifact_root, 'results');
else
    error('validate_stage8_formal_artifact_root:Lifecycle', ...
        'lifecycle must be CALIBRATION or VALIDATION.');
end
if opts.require_empty_lifecycle
    files = dir(fullfile(folder, '**', '*'));
    files = files(~[files.isdir]);
    files = files(~strcmp({files.name}, '.gitkeep'));
    if ~isempty(files)
        error(['validate_stage8_formal_artifact_root:', ...
            'ExistingArtifact'], ...
            'Formal %s evidence requires an empty registered directory.', ...
            lower(char(lifecycle)));
    end
end
end

function value = canonical_path_local(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error('validate_stage8_formal_artifact_root:Path', ...
        'Repository and artifact roots must be scalar paths.');
end
value = char(java.io.File(char(value)).getCanonicalPath());
end
