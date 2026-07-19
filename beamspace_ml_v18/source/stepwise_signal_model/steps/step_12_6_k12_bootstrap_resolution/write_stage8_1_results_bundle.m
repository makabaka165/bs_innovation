function evidence = write_stage8_1_results_bundle(bundle, artifact_root, opts)
%WRITE_STAGE8_1_RESULTS_BUNDLE Write the frozen deterministic evidence set.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
registry = stage8_1_artifact_registry();
if ~isfolder(artifact_root)
    mkdir(artifact_root);
end
written = false(height(registry.table), 1);
for row_index = 1:height(registry.table)
    row = registry.table(row_index, :);
    if row.artifact_id == "EVIDENCE_MANIFEST"
        continue;
    end
    field = char(row.bundle_field);
    if ~isfield(bundle, field)
        if opts.allow_incomplete
            if row.artifact_id == "REPORT"
                payload = "";
            else
                payload = table(string.empty(0, 1), ...
                    'VariableNames', {'empty_payload'});
            end
        else
            error('write_stage8_1_results_bundle:MissingPayload', ...
                'bundle.%s is required.', field);
        end
    else
        payload = bundle.(field);
    end
    path_now = fullfile(artifact_root, char(row.relative_path));
    write_payload_local(path_now, payload, row.artifact_id, opts);
    written(row_index) = true;
end
[manifest, bundle_hash] = build_stage8_1_evidence_manifest( ...
    artifact_root, registry);
manifest_path = fullfile(artifact_root, char(registry.table.relative_path( ...
    registry.table.artifact_id == "EVIDENCE_MANIFEST")));
write_payload_local(manifest_path, manifest, "EVIDENCE_MANIFEST", opts);
written(registry.table.artifact_id == "EVIDENCE_MANIFEST") = true;
evidence = struct('manifest', manifest, ...
    'stage8_1_evidence_bundle_hash', bundle_hash, ...
    'artifact_registry_hash', registry.registry_hash, ...
    'written_artifact_count', nnz(written), ...
    'all_registered_artifacts_written_flag', all(written), ...
    'runtime_in_bundle_identity_flag', false, ...
    'manifest_self_reference_flag', false);
clear path_cleanup
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('write_stage8_1_results_bundle:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'overwrite','allow_incomplete'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('write_stage8_1_results_bundle:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'overwrite'), opts.overwrite = false; end
if ~isfield(opts, 'allow_incomplete'), opts.allow_incomplete = false; end
end

function write_payload_local(path_now, payload, artifact_id, opts)
folder = fileparts(path_now);
if ~isfolder(folder)
    mkdir(folder);
end
if isfile(path_now) && ~opts.overwrite
    error('write_stage8_1_results_bundle:ExistingArtifact', ...
        'Refusing to overwrite existing artifact: %s.', path_now);
end
if artifact_id == "REPORT"
    if ~(ischar(payload) || (isstring(payload) && isscalar(payload)))
        error('write_stage8_1_results_bundle:Report', ...
            'report_text must be scalar text.');
    end
    fid = fopen(path_now, 'w');
    if fid < 0
        error('write_stage8_1_results_bundle:Open', ...
            'Unable to open %s.', path_now);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', char(payload));
    clear cleanup
else
    if isstruct(payload)
        payload = struct2table(payload);
    end
    if ~istable(payload)
        error('write_stage8_1_results_bundle:TablePayload', ...
            'Artifact %s requires a table-compatible payload.', artifact_id);
    end
    writetable(payload, path_now);
end
end
