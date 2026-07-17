function table_out = validate_stage6_required_artifacts( ...
    step_dir, registry, opts)
%VALIDATE_STAGE6_REQUIRED_ARTIFACTS Check explicit required output paths.

if nargin < 3 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
if isstring(step_dir), step_dir = char(step_dir); end
required_columns = {'artifact_id','relative_path','required_by_runner'};
if ~(ischar(step_dir) && isrow(step_dir) && exist(step_dir, 'dir') == 7 && ...
        istable(registry) && ...
        all(ismember(required_columns, registry.Properties.VariableNames)))
    error('validate_stage6_required_artifacts:Inputs', ...
        'An existing step_dir and valid artifact registry are required.');
end
if numel(unique(string(registry.relative_path))) ~= height(registry)
    error('validate_stage6_required_artifacts:Duplicate', ...
        'Artifact registry paths must be unique.');
end

selected = registry(logical(registry.required_by_runner), :);
artifact_path = strings(height(selected), 1);
exists_flag = false(height(selected), 1);
for index = 1:height(selected)
    relative = replace(string(selected.relative_path(index)), '\', '/');
    components = split(relative, '/');
    if startsWith(relative, '/') || ...
            ~isempty(regexp(char(relative), '^[A-Za-z]:', 'once')) || ...
            any(components == "..")
        error('validate_stage6_required_artifacts:Path', ...
            'Artifact registry paths must remain under step_dir.');
    end
    artifact_path(index) = string(fullfile(step_dir, char(relative)));
    exists_flag(index) = exist(char(artifact_path(index)), 'file') == 2;
end
pass_flag = exists_flag;
table_out = table(string(selected.artifact_id), ...
    string(selected.relative_path), artifact_path, exists_flag, pass_flag, ...
    'VariableNames', {'artifact_id','relative_path','artifact_path', ...
    'exists_flag','pass_flag'});
if opts.throw_on_missing && ~all(pass_flag)
    missing = strjoin(table_out.relative_path(~pass_flag), ', ');
    error('validate_stage6_required_artifacts:Missing', ...
        'Required stage-6 artifacts are missing: %s.', missing);
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('validate_stage6_required_artifacts:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'throw_on_missing'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('validate_stage6_required_artifacts:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'throw_on_missing'), opts.throw_on_missing = true; end
if ~(islogical(opts.throw_on_missing) && isscalar(opts.throw_on_missing))
    error('validate_stage6_required_artifacts:ThrowOption', ...
        'throw_on_missing must be a logical scalar.');
end
end
