function table_out = validate_stage6_required_artifacts( ...
    step_dir, registry, opts)
%VALIDATE_STAGE6_REQUIRED_ARTIFACTS Validate core or final-freeze artifacts.

if nargin < 3 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
if isstring(step_dir), step_dir = char(step_dir); end
required_columns = {'artifact_id','relative_path', ...
    'required_by_core_runner','required_by_final_freeze'};
if ~(ischar(step_dir) && isrow(step_dir) && exist(step_dir, 'dir') == 7 && ...
        istable(registry) && ...
        all(ismember(required_columns, registry.Properties.VariableNames)))
    error('validate_stage6_required_artifacts:Inputs', ...
        'An existing step_dir and final-freeze artifact registry are required.');
end
if numel(unique(string(registry.artifact_id))) ~= height(registry) || ...
        numel(unique(string(registry.relative_path))) ~= height(registry)
    error('validate_stage6_required_artifacts:Duplicate', ...
        'Artifact registry ids and paths must be unique.');
end

if opts.validation_scope == "CORE_RUNNER"
    required_mask = logical(registry.required_by_core_runner);
else
    required_mask = logical(registry.required_by_final_freeze);
end
selected = registry(required_mask, :);
artifact_path = strings(height(selected), 1);
exists_flag = false(height(selected), 1);
for index = 1:height(selected)
    relative = validate_relative_path_local(selected.relative_path(index));
    artifact_path(index) = string(fullfile(step_dir, char(relative)));
    exists_flag(index) = exist(char(artifact_path(index)), 'file') == 2;
end
validation_scope = repmat(opts.validation_scope, height(selected), 1);
pass_flag = exists_flag;
table_out = table(string(selected.artifact_id), ...
    string(selected.relative_path), artifact_path, validation_scope, ...
    exists_flag, pass_flag, 'VariableNames', {'artifact_id','relative_path', ...
    'artifact_path','validation_scope','exists_flag','pass_flag'});
if opts.throw_on_missing && ~all(pass_flag)
    missing = strjoin(table_out.relative_path(~pass_flag), ', ');
    error('validate_stage6_required_artifacts:Missing', ...
        'Required %s artifacts are missing: %s.', ...
        opts.validation_scope, missing);
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('validate_stage6_required_artifacts:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'throw_on_missing','validation_scope'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('validate_stage6_required_artifacts:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'throw_on_missing'), opts.throw_on_missing = true; end
if ~isfield(opts, 'validation_scope'), opts.validation_scope = "CORE_RUNNER"; end
if ~(islogical(opts.throw_on_missing) && isscalar(opts.throw_on_missing))
    error('validate_stage6_required_artifacts:ThrowOption', ...
        'throw_on_missing must be a logical scalar.');
end
if ischar(opts.validation_scope), opts.validation_scope = string(opts.validation_scope); end
if ~(isstring(opts.validation_scope) && isscalar(opts.validation_scope) && ...
        ismember(opts.validation_scope, ["CORE_RUNNER", "FINAL_FREEZE"]))
    error('validate_stage6_required_artifacts:ValidationScope', ...
        'validation_scope must be CORE_RUNNER or FINAL_FREEZE.');
end
end

function relative = validate_relative_path_local(relative)
relative = replace(string(relative), '\', '/');
components = split(relative, '/');
if ismissing(relative) || strlength(relative) == 0 || ...
        startsWith(relative, '/') || ...
        ~isempty(regexp(char(relative), '^[A-Za-z]:', 'once')) || ...
        any(components == "..")
    error('validate_stage6_required_artifacts:Path', ...
        'Artifact registry paths must remain under step_dir.');
end
end
