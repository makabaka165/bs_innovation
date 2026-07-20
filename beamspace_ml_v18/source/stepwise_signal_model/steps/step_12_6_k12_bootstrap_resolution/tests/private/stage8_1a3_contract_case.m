function result = stage8_1a3_contract_case(case_id)
%STAGE8_1A3_CONTRACT_CASE Execute one named A3 contract assertion.

switch string(case_id)
    case "nonconverged_high_likelihood_start_not_selected"
        [rows, expected] = start_rows_local();
        rows(2).loglik_concentrated = 100;
        rows(2).converged_flag = false;
        [index, diagnostics] = select_stage8_valid_registered_start( ...
            rows, 1, expected);
        pass = index == 1 && diagnostics.valid_start_count == 1 && ...
            diagnostics.nonconverged_start_count == 1;
    case "converged_lower_likelihood_start_selected"
        [rows, expected] = start_rows_local();
        rows(1).loglik_concentrated = 2;
        rows(2).loglik_concentrated = 9;
        rows(2).converged_flag = false;
        index = select_stage8_valid_registered_start(rows, 1, expected);
        pass = index == 1;
    case "all_nonconverged_starts_return_search_not_converged"
        [rows, expected] = start_rows_local();
        [rows.converged_flag] = deal(false);
        [index, diagnostics] = select_stage8_valid_registered_start( ...
            rows, 1, expected);
        pass = index == 0 && diagnostics.nonconverged_start_count == 2 && ...
            diagnostics.rank_deficient_start_count == 0;
    case "rank_deficient_starts_not_selected"
        [rows, expected] = start_rows_local();
        rows(2).loglik_concentrated = 100;
        rows(2).effective_rank = 0;
        [index, diagnostics] = select_stage8_valid_registered_start( ...
            rows, 1, expected);
        pass = index == 1 && diagnostics.rank_deficient_start_count == 1;
    case "all_registered_starts_still_charged"
        [rows, expected] = start_rows_local();
        rows(1).num_score_eval = 11;
        rows(2).num_score_eval = 17;
        rows(2).converged_flag = false;
        [~, ~, returned] = select_stage8_valid_registered_start( ...
            rows, 1, expected);
        pass = numel(returned) == 2 && ...
            sum([returned.num_score_eval]) == 28;
    case "selected_start_is_valid_for_lrt"
        [rows, expected] = start_rows_local();
        [index, ~, returned] = select_stage8_valid_registered_start( ...
            rows, 1, expected);
        pass = index > 0 && validate_stage8_fit_for_lrt( ...
            returned(index), 1, expected);
    case "threshold_v3_hex_roundtrip"
        [thresholds, contract] = build_stage8_1a_threshold_fixture();
        restored = lookup_locked_lrt_threshold( ...
            'MINI_PRIMARY', thresholds, contract);
        pass = isequal(num2hex(restored.q_global), restored.q_global_hex) && ...
            isequal(num2hex(restored.alpha), restored.alpha_hex);
    case "threshold_v3_hash_fixed_field_order"
        [thresholds, ~] = build_stage8_1a_threshold_fixture();
        first = thresholds(1);
        first.runtime_note = 'IGNORED_METADATA';
        names = flip(fieldnames(first));
        reordered = orderfields(first, names);
        pass = strcmp(stage8_threshold_artifact_hash(first), ...
            stage8_threshold_artifact_hash(reordered));
    case "threshold_decimal_tamper_fails"
        [thresholds, contract] = build_stage8_1a_threshold_fixture();
        thresholds(1).q_global = thresholds(1).q_global + 1;
        stage8_assert_error(@() lookup_locked_lrt_threshold( ...
            'MINI_PRIMARY', thresholds, contract), ...
            'lookup_locked_lrt_threshold:DecimalHexMismatch');
        pass = true;
    case "threshold_hex_tamper_fails"
        [thresholds, contract] = build_stage8_1a_threshold_fixture();
        thresholds(1).q_global_hex = num2hex(6);
        stage8_assert_error(@() lookup_locked_lrt_threshold( ...
            'MINI_PRIMARY', thresholds, contract), ...
            'lookup_locked_lrt_threshold:ArtifactHash');
        pass = true;
    case "calibration_freezer_writes_no_validation_placeholder"
        context = build_stage8_1a_frozen_evidence_fixture();
        pass = ~isfolder(fullfile(context.artifact_root, 'results'));
    case "calibration_manifest_determinism"
        first = build_stage8_1a_frozen_evidence_fixture();
        second = build_stage8_1a_frozen_evidence_fixture(true);
        pass = strcmp(first.frozen.calibration_evidence_bundle_hash, ...
            second.frozen.calibration_evidence_bundle_hash) && ...
            isequal(first.frozen.manifest.sha256, second.frozen.manifest.sha256);
    case "calibration_bundle_excludes_runtime_and_manifest"
        context = build_stage8_1a_frozen_evidence_fixture();
        ids = string(context.frozen.manifest.artifact_id);
        pass = ~any(ids == "CALIBRATION_EVIDENCE_MANIFEST") && ...
            ~any(ids == "RUNTIME_DIAGNOSTICS");
    case "committed_threshold_loader_requires_tracked_artifacts"
        context = build_stage8_1a_frozen_evidence_fixture();
        stage8_assert_error(@() load_stage8_1_locked_thresholds( ...
            tempdir, context.artifact_root, context.fixture.plan, struct( ...
            'formal_run', false, 'require_tracked_artifacts', true)), ...
            'load_stage8_1_locked_thresholds:DirtyRepository');
        pass = true;
    case "committed_threshold_loader_rejects_stale_source"
        context = build_stage8_1a_frozen_evidence_fixture();
        stale = context.fixture.plan;
        stale.identity.stage8_stable_code_identity_hash = 'STALE_SOURCE';
        stage8_assert_error(@() load_stage8_1_locked_thresholds( ...
            tempdir, context.artifact_root, stale, struct( ...
            'formal_run', false, 'require_tracked_artifacts', false)), ...
            'lookup_locked_lrt_threshold:ProvenanceMismatch');
        pass = true;
    case "committed_threshold_loader_rejects_stale_plan"
        context = build_stage8_1a_frozen_evidence_fixture();
        stale = context.fixture.plan;
        stale.stage8_plan_hash = 'STALE_PLAN';
        stage8_assert_error(@() load_stage8_1_locked_thresholds( ...
            tempdir, context.artifact_root, stale, struct( ...
            'formal_run', false, 'require_tracked_artifacts', false)), ...
            'lookup_locked_lrt_threshold:ProvenanceMismatch');
        pass = true;
    case "committed_threshold_loader_rejects_tampered_cell_results"
        context = build_stage8_1a_frozen_evidence_fixture(true);
        path_now = fullfile(context.artifact_root, 'calibration', ...
            'stage8_1_cell_results.csv');
        data = readtable(path_now, 'TextType', 'string');
        data.q_cell_0p95(1) = data.q_cell_0p95(1) + 1;
        writetable(data, path_now);
        stage8_assert_error(@() load_stage8_1_locked_thresholds( ...
            tempdir, context.artifact_root, context.fixture.plan, struct( ...
            'formal_run', false, 'require_tracked_artifacts', false)), ...
            'load_stage8_1_locked_thresholds:ManifestMismatch');
        pass = true;
    case "committed_threshold_loader_requires_two_configs"
        [thresholds, contract] = build_stage8_1a_threshold_fixture();
        stage8_assert_error(@() validate_stage8_locked_threshold_set( ...
            ["MINI_PRIMARY";"MINI_PARENT"], thresholds(1), contract), ...
            'validate_stage8_locked_threshold_set:ThresholdCount');
        pass = true;
    case "validation_wrapper_uses_committed_threshold_only"
        context = build_stage8_1a_frozen_evidence_fixture();
        output = run_stage8_1_k1_validation_from_frozen_thresholds( ...
            tempdir, struct('formal_run', false, ...
            'require_tracked_artifacts', false, ...
            'calibration_root', context.artifact_root, ...
            'frozen_plan', context.fixture.plan, ...
            'evaluation_callback', @evaluation_local, ...
            'Bsep', 2, 'run_separation', false));
        pass = output.threshold_lookup_only_flag && ...
            strcmp(output.calibration_evidence_bundle_hash, ...
            context.calibration.calibration_evidence_bundle_hash);
    case "finalizer_never_rewrites_calibration_artifacts"
        context = build_stage8_1a_frozen_evidence_fixture();
        [validation_root, validation_cleanup] = validation_root_local(); %#ok<ASGLU>
        before = calibration_snapshot_local(context.artifact_root);
        output = build_stage8_1a_bound_validation_output( ...
            context.fixture.plan, context.calibration);
        run_stage8_1_finalize(context.fixture.plan, context.calibration, ...
            output, validation_root, struct('formal_run', false, ...
            'require_tracked_artifacts', false));
        pass = isequal(before, calibration_snapshot_local( ...
            context.artifact_root));
    case "validation_output_binds_validation_plan_hash"
        [context, output] = validation_context_local();
        validated = validate_stage8_1_validation_output( ...
            context.fixture.plan, context.calibration, output);
        pass = strcmp(validated.validation_plan_hash, ...
            context.fixture.plan.stage8_validation_plan_hash);
    case "validation_output_binds_calibration_bundle_hash"
        [context, output] = validation_context_local();
        validated = validate_stage8_1_validation_output( ...
            context.fixture.plan, context.calibration, output);
        pass = strcmp(validated.calibration_evidence_bundle_hash, ...
            context.calibration.calibration_evidence_bundle_hash);
    case "validation_trial_set_hash_determinism"
        [context, output] = validation_context_local();
        second = build_stage8_1a_bound_validation_output( ...
            context.fixture.plan, context.calibration);
        pass = strcmp(output.validation_trial_set_hash, ...
            second.validation_trial_set_hash);
    case "finalizer_recomputes_14_row_summary"
        [context, output] = validation_context_local();
        validated = validate_stage8_1_validation_output( ...
            context.fixture.plan, context.calibration, output);
        pass = height(validated.summary) == 14 && ...
            strcmp(validated.validation_summary_hash, ...
            output.validation_summary_hash);
    case "finalizer_recomputes_primary_gate"
        [context, output] = validation_context_local();
        validated = validate_stage8_1_validation_output( ...
            context.fixture.plan, context.calibration, output);
        pass = strcmp(validated.primary_gate_hash, ...
            output.primary_gate_hash) && ...
            ~validated.recomputed_primary_gate_pass;
    case "tampered_summary_fails"
        [context, output] = validation_context_local();
        output.summary.false_split_rate(1) = 1;
        derived_error_local(context, output);
        pass = true;
    case "tampered_gate_fails"
        [context, output] = validation_context_local();
        output.gate.gate_pass = ~output.gate.gate_pass;
        derived_error_local(context, output);
        pass = true;
    case "tampered_paired_sensitivity_fails"
        [context, output] = validation_context_local();
        output.paired_sensitivity.false_split_discordance(1) = true;
        derived_error_local(context, output);
        pass = true;
    case "wrong_validation_plan_fails"
        [context, output] = validation_context_local();
        wrong = context.fixture.plan;
        wrong.stage8_validation_plan_hash = 'WRONG_VALIDATION_PLAN';
        stage8_assert_error(@() validate_stage8_1_validation_output( ...
            wrong, context.calibration, output), ...
            'validate_stage8_1_validation_output:ProvenanceMismatch');
        pass = true;
    case "full_parent_cannot_authorize_stage8_2"
        context = build_stage8_1a_frozen_evidence_fixture();
        output = build_stage8_1a_bound_validation_output( ...
            context.fixture.plan, context.calibration, 'K1', 'K2_RESOLVED');
        validated = validate_stage8_1_validation_output( ...
            context.fixture.plan, context.calibration, output);
        pass = ~validated.gate.sensitivity_used_for_authorization_flag && ...
            strcmp(validated.gate.authorization_measurement_config_id, ...
            'MINI_PRIMARY');
    case "final_bundle_references_calibration_bundle"
        [context, output] = validation_context_local();
        [validation_root, validation_cleanup] = validation_root_local(); %#ok<ASGLU>
        evidence = run_stage8_1_finalize(context.fixture.plan, ...
            context.calibration, output, validation_root, struct( ...
            'formal_run', false, 'require_tracked_artifacts', false));
        pass = all(evidence.manifest.calibration_evidence_bundle_hash == ...
            string(context.calibration.calibration_evidence_bundle_hash));
    case "stage8_2_still_not_executed"
        [context, output] = validation_context_local();
        [validation_root, validation_cleanup] = validation_root_local(); %#ok<ASGLU>
        evidence = run_stage8_1_finalize(context.fixture.plan, ...
            context.calibration, output, validation_root, struct( ...
            'formal_run', false, 'require_tracked_artifacts', false));
        pass = ~evidence.stage8_2_executed_flag && ...
            evidence.stage8_2_separate_authorization_required_flag;
    otherwise
        error('stage8_1a3_contract_case:UnknownCase', ...
            'Unknown Stage8.1A3 case: %s.', case_id);
end
assert(pass, 'stage8_1a3_contract_case:Failed', ...
    'Stage8.1A3 contract case failed: %s.', case_id);
result = table(pass, string(case_id), ...
    'VariableNames', {'pass_flag','case_id'});
end

function [rows, expected] = start_rows_local()
expected = struct('fixed_measurement_hash', 'M', ...
    'local_domain_hash', 'D', 'solver_contract_hash', 'S', ...
    'observation_hash', 'O');
base = struct('K', 1, 'initialization_available_flag', true, ...
    'estimate_returned_flag', true, 'converged_flag', true, ...
    'effective_rank', 1, 'rss', 1, 'sigma2_hat', 1, ...
    'loglik_concentrated', 1, 'fixed_measurement_hash', 'M', ...
    'local_domain_hash', 'D', 'solver_contract_hash', 'S', ...
    'observation_hash', 'O', 'phase_factor', 1, ...
    'num_score_eval', 1);
rows = repmat(base, 2, 1);
rows(2).loglik_concentrated = 2;
end

function [context, output] = validation_context_local()
context = build_stage8_1a_frozen_evidence_fixture();
output = build_stage8_1a_bound_validation_output( ...
    context.fixture.plan, context.calibration);
end

function derived_error_local(context, output)
stage8_assert_error(@() validate_stage8_1_validation_output( ...
    context.fixture.plan, context.calibration, output), ...
    'validate_stage8_1_validation_output:DerivedEvidenceMismatch');
end

function evaluation = evaluation_local(~, ~, ~, ~)
evaluation = struct('state', 'K1', 'lambda_12', 0, ...
    'fit1_validity_status', 'VALID_FOR_LRT', ...
    'fit2_validity_status', 'VALID_FOR_LRT', ...
    'separation_status', 'NOT_RUN_MINIATURE_CONTRACT');
end

function snapshot = calibration_snapshot_local(root)
files = dir(fullfile(root, 'calibration', '*'));
files = files(~[files.isdir]);
names = string({files.name}).';
hashes = strings(numel(files), 1);
for index = 1:numel(files)
    hashes(index) = string(stage8_sha256_file( ...
        fullfile(files(index).folder, files(index).name)));
end
snapshot = sortrows(table(names, hashes), 'names');
end

function [root, cleanup] = validation_root_local()
root = tempname;
mkdir(root);
cleanup = onCleanup(@() rmdir(root, 's'));
end
