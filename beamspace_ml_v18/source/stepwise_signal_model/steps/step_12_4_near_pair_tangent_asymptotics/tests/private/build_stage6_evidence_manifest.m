function [manifest, bundle] = build_stage6_evidence_manifest( ...
    step_dir, registry, opts)
%BUILD_STAGE6_EVIDENCE_MANIFEST Hash generated files and bundle identities.

if nargin < 3 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
validate_inputs_local(step_dir, registry);
n = height(registry);
byte_count = nan(n, 1);
sha256 = strings(n, 1);
file_exists_flag = false(n, 1);
required_for_scope = required_mask_local(registry, opts.validation_scope);
pass_flag = false(n, 1);
for index = 1:n
    relative = validate_relative_path_local(registry.relative_path(index));
    path_now = fullfile(step_dir, char(relative));
    temporary_path = '';
    if registry.artifact_id(index) == "stage6_reproduction_comparison" && ...
            ~isempty(opts.comparison_table)
        temporary_path = [tempname, '.csv'];
        comparison_output = build_stage6_reproduction_comparison_output( ...
            opts.comparison_table, opts.comparison_summary);
        write_stage6_comparison_csv(temporary_path, comparison_output);
        source_path = temporary_path;
        file_exists_flag(index) = true;
    else
        source_path = path_now;
        file_exists_flag(index) = exist(path_now, 'file') == 2;
    end
    if file_exists_flag(index)
        details = dir(source_path);
        byte_count(index) = details.bytes;
        sha256(index) = string(stage6_sha256_file(source_path));
        if ~isempty(temporary_path), delete(temporary_path); end
    elseif registry.self_referential_exclusion_flag(index)
        sha256(index) = "SELF_REFERENTIAL_EXCLUSION";
    else
        sha256(index) = "MISSING";
    end
    allowed_missing_self = opts.allow_missing_self_referential_artifacts && ...
        registry.self_referential_exclusion_flag(index);
    pass_flag(index) = file_exists_flag(index) || ...
        ~required_for_scope(index) || allowed_missing_self;
end
manifest = table(string(registry.artifact_id), ...
    string(registry.relative_path), string(registry.artifact_type), ...
    string(registry.evidence_class), byte_count, sha256, ...
    logical(registry.required_by_core_runner), ...
    logical(registry.required_by_final_freeze), ...
    logical(registry.included_in_deterministic_bundle), ...
    logical(registry.self_referential_exclusion_flag), ...
    file_exists_flag, pass_flag, 'VariableNames', { ...
    'artifact_id','relative_path','artifact_type','evidence_class', ...
    'byte_count','sha256','required_by_core_runner', ...
    'required_by_final_freeze','included_in_deterministic_bundle', ...
    'self_referential_exclusion_flag','file_exists_flag','pass_flag'});

included = manifest.included_in_deterministic_bundle & ...
    manifest.file_exists_flag;
included_rows = sortrows(manifest(included, :), 'relative_path');
payload = uint8([]);
for index = 1:height(included_rows)
    payload = [payload, utf8_local(included_rows.relative_path(index)), ...
        uint8(0), utf8_local(included_rows.sha256(index))]; %#ok<AGROW>
end
bundle_hash = sha256_bytes_local(payload);
all_required_present = all(pass_flag);
required_bundle_missing = any(required_for_scope & ...
    registry.included_in_deterministic_bundle & ~file_exists_flag);
bundle_pass = all_required_present && ~required_bundle_missing;
stage6_evidence_bundle_hash = string(bundle_hash);
deterministic_artifact_count = height(included_rows);
deterministic_total_bytes = sum(included_rows.byte_count);
excluded_runtime_artifact_count = nnz( ...
    registry.evidence_class == "RUNTIME_DIAGNOSTIC");
excluded_figure_artifact_count = nnz( ...
    registry.evidence_class == "FIGURE_DIAGNOSTIC");
excluded_self_referential_artifact_count = nnz( ...
    registry.self_referential_exclusion_flag);
bundle_contract_version = "STAGE6_DETERMINISTIC_EVIDENCE_BUNDLE_V1";
pass_flag = bundle_pass;
bundle = table(stage6_evidence_bundle_hash, ...
    deterministic_artifact_count, deterministic_total_bytes, ...
    excluded_runtime_artifact_count, excluded_figure_artifact_count, ...
    excluded_self_referential_artifact_count, bundle_contract_version, ...
    pass_flag);
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_stage6_evidence_manifest:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'validation_scope','allow_missing_self_referential_artifacts', ...
    'comparison_table','comparison_summary'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_stage6_evidence_manifest:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'validation_scope'), opts.validation_scope = "FINAL_FREEZE"; end
if ~isfield(opts, 'allow_missing_self_referential_artifacts')
    opts.allow_missing_self_referential_artifacts = false;
end
if ~isfield(opts, 'comparison_table'), opts.comparison_table = table(); end
if ~isfield(opts, 'comparison_summary'), opts.comparison_summary = table(); end
if ischar(opts.validation_scope), opts.validation_scope = string(opts.validation_scope); end
if ~(isstring(opts.validation_scope) && isscalar(opts.validation_scope) && ...
        ismember(opts.validation_scope, ["CORE_RUNNER", "FINAL_FREEZE"]))
    error('build_stage6_evidence_manifest:ValidationScope', ...
        'validation_scope must be CORE_RUNNER or FINAL_FREEZE.');
end
if ~(islogical(opts.allow_missing_self_referential_artifacts) && ...
        isscalar(opts.allow_missing_self_referential_artifacts))
    error('build_stage6_evidence_manifest:SelfReferenceOption', ...
        'allow_missing_self_referential_artifacts must be logical.');
end
if ~istable(opts.comparison_table)
    error('build_stage6_evidence_manifest:ComparisonTable', ...
        'comparison_table must be a table.');
end
if ~istable(opts.comparison_summary) || ...
        (~isempty(opts.comparison_table) && isempty(opts.comparison_summary))
    error('build_stage6_evidence_manifest:ComparisonSummary', ...
        'An in-memory comparison requires its summary table.');
end
end

function validate_inputs_local(step_dir, registry)
if isstring(step_dir), step_dir = char(step_dir); end
required = {'artifact_id','relative_path','artifact_type','evidence_class', ...
    'required_by_core_runner','required_by_final_freeze', ...
    'included_in_deterministic_bundle','self_referential_exclusion_flag'};
if ~(ischar(step_dir) && isrow(step_dir) && exist(step_dir, 'dir') == 7 && ...
        istable(registry) && all(ismember(required, ...
        registry.Properties.VariableNames)))
    error('build_stage6_evidence_manifest:Inputs', ...
        'An existing step_dir and valid artifact registry are required.');
end
if numel(unique(string(registry.artifact_id))) ~= height(registry) || ...
        numel(unique(string(registry.relative_path))) ~= height(registry)
    error('build_stage6_evidence_manifest:Duplicate', ...
        'Registry ids and paths must be unique.');
end
end

function required = required_mask_local(registry, scope)
if scope == "CORE_RUNNER"
    required = logical(registry.required_by_core_runner);
else
    required = logical(registry.required_by_final_freeze);
end
end

function relative = validate_relative_path_local(relative)
relative = replace(string(relative), '\', '/');
components = split(relative, '/');
if ismissing(relative) || strlength(relative) == 0 || ...
        startsWith(relative, '/') || ...
        ~isempty(regexp(char(relative), '^[A-Za-z]:', 'once')) || ...
        any(components == "..")
    error('build_stage6_evidence_manifest:Path', ...
        'Registry paths must remain below step_dir.');
end
end

function bytes = utf8_local(value)
bytes = uint8(unicode2native(char(value), 'UTF-8'));
end

function digest = sha256_bytes_local(payload)
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(payload);
bytes = typecast(md.digest(), 'uint8');
digest = lower(reshape(dec2hex(bytes, 2).', 1, []));
end
