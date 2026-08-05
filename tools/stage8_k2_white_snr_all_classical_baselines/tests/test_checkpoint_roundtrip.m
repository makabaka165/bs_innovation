function result = test_checkpoint_roundtrip(fixture)
%TEST_CHECKPOINT_ROUNDTRIP Verify temp, hash, rename, skip, and hard stop.

runtime_root = tempname;
mkdir(runtime_root); mkdir(fullfile(runtime_root, 'checkpoints'));
cleanup = onCleanup(@() cleanup_local(runtime_root));
spec = fixture.registry(1, :);
[trial, ~, identity] = stage8_k2_wacb_reconstruct_trial( ...
    spec, fixture.context);
[rows, diagnostics] = fixture_rows_local(spec, trial, fixture.context);
representative = struct('included', false, 'trial_id', spec.trial_id);
registry_hash = stage8_k2_wacb_stable_hash('TEST_REGISTRY', spec);
[checkpoint, path_now] = stage8_k2_wacb_checkpoint_write( ...
    runtime_root, spec, identity, rows, diagnostics, representative, ...
    fixture.context, registry_hash, 1.25);
audit = stage8_k2_wacb_checkpoint_validate( ...
    path_now, spec, fixture.context, registry_hash);
scan = stage8_k2_wacb_scan_checkpoints( ...
    runtime_root, spec, fixture.context, registry_hash);
exists_rejected = false;
try
    stage8_k2_wacb_checkpoint_write(runtime_root, spec, identity, rows, ...
        diagnostics, representative, fixture.context, registry_hash, 1.25);
catch exception
    exists_rejected = strcmp(exception.identifier, ...
        'stage8_k2_wacb_checkpoint_write:Exists');
end
loaded = load(path_now, 'checkpoint', '-mat');
loaded.checkpoint.scientific_hash = 'tampered';
tampered_path = [path_now, '.tampered'];
checkpoint_tampered = loaded.checkpoint; %#ok<NASGU>
save(tampered_path, 'checkpoint_tampered', '-mat');
schema_rejected = false;
try
    stage8_k2_wacb_checkpoint_validate( ...
        tampered_path, spec, fixture.context, registry_hash);
catch
    schema_rejected = true;
end
assert(audit.pass && scan.completed_count == 1 && ...
    ~isfile([path_now, '.tmp']) && exists_rejected && schema_rejected, ...
    'test_checkpoint_roundtrip:Contract', ...
    'Checkpoint roundtrip, skip, or hard-stop behavior failed.');
result = struct('pass', true, 'scientific_hash', ...
    checkpoint.scientific_hash, 'resume_skip_count', 1, ...
    'existing_final_rejected', exists_rejected, ...
    'invalid_final_rejected', schema_rejected);
clear cleanup
end

function [rows, diagnostics] = fixture_rows_local(spec, trial, context)
snr_row = context.evidence44.snr_rows( ...
    context.evidence44.snr_rows.trial_id == spec.trial_id, :);
methods = context.constants.method_ids;
row_structs = cell(4, 1);
diagnostic_structs = repmat(struct('trial_id', spec.trial_id, ...
    'element_trial_hash', trial.element_trial_hash, ...
    'method_id', methods(1), 'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false), 4, 1);
for index = 1:4
    rule = stage8_k2_wacb_applicability(spec, methods(index));
    fit = result_local(methods(index));
    fit.applicable = rule.applicable;
    fit.applicability_status = rule.status;
    fit.fit_status = rule.status;
    fit.failure_stage = "STRUCTURAL_NA";
    row_structs{index} = stage8_k2_wacb_result_row( ...
        spec, trial, snr_row, fit, context.constants);
    diagnostic_structs(index).method_id = methods(index);
end
rows = struct2table(vertcat(row_structs{:}));
diagnostics = struct2table(diagnostic_structs);
end

function value = result_local(method)
value = struct('method_id', method, 'applicable', false, ...
    'applicability_status', "STRUCTURAL_NA", 'fit_valid', false, ...
    'fit_status', "STRUCTURAL_NA", 'failure_stage', "STRUCTURAL_NA", ...
    'angles_hat_deg', NaN(2, 2), 'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false, 'tangent_used_in_start_flag', false, ...
    'core_used_in_start_flag', false, 'full4d_used_in_start_flag', false);
end

function cleanup_local(path_now)
if isfolder(path_now), rmdir(path_now, 's'); end
end
