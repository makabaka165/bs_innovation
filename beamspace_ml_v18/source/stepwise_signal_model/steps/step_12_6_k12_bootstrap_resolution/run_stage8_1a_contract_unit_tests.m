function report = run_stage8_1a_contract_unit_tests()
%RUN_STAGE8_1A_CONTRACT_UNIT_TESTS Run miniature Stage8.1A code-only gates.

step_dir = fileparts(mfilename('fullpath'));
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
package_dir = fileparts(fileparts(project_dir));
repo_dir = fileparts(package_dir);
old_path = path;
path_cleanup = onCleanup(@() path(old_path));
addpath(fullfile(project_dir, 'core', 'config'));
addpath(fullfile(project_dir, 'core', 'array'));
addpath(fullfile(steps_dir, 'step_12_0_receive_model_correction', 'common'));
addpath(fullfile(steps_dir, 'step_12_1_sequential_dbf_model', 'common'));
addpath(fullfile(steps_dir, 'step_12_2_stable_dml_backend', 'common'));
addpath(fullfile(steps_dir, 'step_12_3_grouped_conditional_dml', 'common'));
addpath(fullfile(steps_dir, ...
    'step_12_4_near_pair_tangent_asymptotics', 'common'));
addpath(fullfile(steps_dir, ...
    'step_12_5_exact_subset_fim_beam_design', 'common'));
addpath(step_dir);
addpath(fullfile(step_dir, 'common'));
addpath(fullfile(step_dir, 'tests'));

cfg = sim_cfg();
assert(strcmp(version('-release'), '2022b') && ...
    cfg.beam.spatialPhaseFactor == 1, ...
    'run_stage8_1a_contract_unit_tests:Runtime', ...
    'Stage8.1A tests require MATLAB R2022b and phase_factor=1.');
registry = build_stage8_measurement_registry(cfg, struct());
calibration = build_stage8_calibration_plan(registry);
validation = build_stage8_validation_plan();
holdout = build_stage8_holdout_plan();

tests = struct();
tests.seed_blocks = test_calibration_bootstrap_seed_blocks_unique(calibration);
tests.seed_data_bootstrap = ...
    test_calibration_data_and_bootstrap_seeds_disjoint(calibration);
tests.seed_all_splits = ...
    test_calibration_validation_holdout_seed_spaces_disjoint( ...
    calibration, validation, holdout);
tests.model_resolution = test_cell_resolves_correct_noise_model(registry);
tests.model_cross_noise = ...
    test_cross_noise_cells_use_distinct_fixed_measurement_hash(registry);
tests.threshold_noise_aggregation = ...
    test_q_global_aggregates_both_noise_profiles();
tests.element_mean = test_element_bootstrap_mean_matches_whitened_fit();
tests.element_whitening = test_element_bootstrap_noise_whitens_to_identity();
tests.element_retained = test_formal_bootstrap_retains_element_data();
tests.real_init_k1 = test_real_initialization_context_k1_fields();
tests.real_init_k2 = test_real_initialization_context_k2_partition_fields();
tests.real_init_no_simulation_metadata = ...
    test_real_initialization_context_uses_no_truth();
tests.bootstrap_rebuild = test_each_bootstrap_rebuilds_initialization_context();
tests.reject_k1 = test_calibration_rejects_nonconverged_k1();
tests.reject_k2 = test_calibration_rejects_nonconverged_k2();
tests.reject_rank = test_calibration_rejects_rank_deficient_fit();
tests.checkpoint_determinism = test_calibration_cell_checkpoint_determinism();
tests.checkpoint_mismatch = test_calibration_resume_hash_mismatch_fails();
tests.require_300 = ...
    test_all_300_cells_required_before_global_threshold(calibration);
tests.all_seeds = test_all_59700_bootstrap_seeds_unique(calibration);
tests.validation_pairing = ...
    test_validation_common_trials_pair_measurement_configs();
tests.validation_lookup = test_validation_threshold_lookup_only();
tests.validation_no_recalibration = test_validation_does_not_recalibrate();
tests.primary_gate_n = test_primary_validation_gate_uses_6000_trials();
tests.primary_stratum_n = test_primary_stratum_gate_uses_1000_trials();
tests.sensitivity_not_authorization = ...
    test_full_parent_not_used_for_authorization();
tests.paired_not_pooled = test_paired_rows_not_pooled_as_independent();
tests.validation_summary_rows = test_validation_summary_has_14_rows();
tests.threshold_source_mismatch = ...
    test_threshold_source_identity_mismatch_fails();
tests.threshold_plan_mismatch = test_threshold_plan_hash_mismatch_fails();
tests.threshold_registry_mismatch = ...
    test_threshold_measurement_registry_mismatch_fails();
tests.finalize_threshold_count = test_finalize_requires_exactly_two_thresholds();
tests.formal_shard_subset = ...
    test_formal_shard_materializes_only_requested_cells();
tests.shard_full_hash = test_shard_and_full_cell_input_hash_match();
tests.formal_checkpoint_root = ...
    test_formal_checkpoint_root_must_be_outside_repo();
tests.collect_checkpoints = test_collect_all_300_checkpoints(calibration);
tests.missing_checkpoint = test_missing_checkpoint_fails(calibration);
tests.duplicate_checkpoint = test_duplicate_checkpoint_fails(calibration);
tests.group_noise_unavailable = ...
    test_group_noise_invalid_makes_start_unavailable();
tests.group_noise_no_unit = ...
    test_group_noise_invalid_does_not_use_unit_fallback();
tests.validation_rng_disjoint = ...
    test_validation_parameter_noise_seeds_disjoint();
tests.validation_rng_pairing = ...
    test_validation_roles_share_pairing_across_configs();
tests.validation_aux_substreams = ...
    test_validation_auxiliary_substreams_deterministic();
tests.start_nonconverged_high = ...
    test_nonconverged_high_likelihood_start_not_selected();
tests.start_converged_lower = ...
    test_converged_lower_likelihood_start_selected();
tests.start_all_nonconverged = ...
    test_all_nonconverged_starts_return_search_not_converged();
tests.start_rank_deficient = test_rank_deficient_starts_not_selected();
tests.start_all_charged = test_all_registered_starts_still_charged();
tests.start_selected_valid = test_selected_start_is_valid_for_lrt();
tests.threshold_v3_roundtrip = test_threshold_v3_hex_roundtrip();
tests.threshold_v3_order = test_threshold_v3_hash_fixed_field_order();
tests.threshold_decimal_tamper = test_threshold_decimal_tamper_fails();
tests.threshold_hex_tamper = test_threshold_hex_tamper_fails();
tests.calibration_no_placeholder = ...
    test_calibration_freezer_writes_no_validation_placeholder();
tests.calibration_manifest_determinism = ...
    test_calibration_manifest_determinism();
tests.calibration_bundle_exclusions = ...
    test_calibration_bundle_excludes_runtime_and_manifest();
tests.loader_requires_tracked = ...
    test_committed_threshold_loader_requires_tracked_artifacts();
tests.loader_rejects_stale_source = ...
    test_committed_threshold_loader_rejects_stale_source();
tests.loader_rejects_stale_plan = ...
    test_committed_threshold_loader_rejects_stale_plan();
tests.loader_rejects_tamper = ...
    test_committed_threshold_loader_rejects_tampered_cell_results();
tests.loader_two_configs = ...
    test_committed_threshold_loader_requires_two_configs();
tests.validation_committed_only = ...
    test_validation_wrapper_uses_committed_threshold_only();
tests.finalizer_calibration_immutable = ...
    test_finalizer_never_rewrites_calibration_artifacts();
tests.validation_plan_binding = ...
    test_validation_output_binds_validation_plan_hash();
tests.validation_calibration_binding = ...
    test_validation_output_binds_calibration_bundle_hash();
tests.validation_trial_hash = ...
    test_validation_trial_set_hash_determinism();
tests.finalizer_summary = test_finalizer_recomputes_14_row_summary();
tests.finalizer_gate = test_finalizer_recomputes_primary_gate();
tests.finalizer_summary_tamper = test_tampered_summary_fails();
tests.finalizer_gate_tamper = test_tampered_gate_fails();
tests.finalizer_paired_tamper = ...
    test_tampered_paired_sensitivity_fails();
tests.validation_wrong_plan = test_wrong_validation_plan_fails();
tests.validation_primary_only = ...
    test_full_parent_cannot_authorize_stage8_2();
tests.final_bundle_calibration_reference = ...
    test_final_bundle_references_calibration_bundle();
tests.stage8_2_still_not_executed = test_stage8_2_still_not_executed();
tests.unreturned_no_crash = ...
    test_unreturned_registered_start_does_not_crash();
tests.unreturned_not_selected = test_unreturned_start_is_not_selected();
tests.valid_peer_survives = test_valid_start_survives_peer_runtime_failure();
tests.all_unreturned = ...
    test_all_unreturned_starts_return_search_not_converged();
tests.unreturned_auditable = ...
    test_unreturned_start_still_appears_in_all_start_results();
tests.failure_counters_disjoint = ...
    test_start_failure_counters_are_disjoint();
tests.no_dead_rank_counter = ...
    test_fit_local_model_has_no_dead_rank_failure_counter();
tests.formal_loader_tracked = ...
    test_formal_loader_cannot_disable_tracked_artifacts();
tests.formal_wrapper_tracked = ...
    test_formal_validation_wrapper_cannot_disable_tracked_artifacts();
tests.formal_finalizer_tracked = ...
    test_formal_finalizer_cannot_disable_tracked_artifacts();
tests.nonformal_untracked_fixture = ...
    test_nonformal_loader_may_use_untracked_fixture();
tests.formal_freeze_no_overwrite = ...
    test_formal_threshold_freeze_forbids_overwrite();
tests.formal_finalize_no_overwrite = ...
    test_formal_validation_finalize_forbids_overwrite();
tests.formal_calibration_root = ...
    test_formal_calibration_artifact_root_is_registered();
tests.formal_validation_root = ...
    test_formal_validation_artifact_root_is_registered();
tests.formal_external_root = ...
    test_formal_artifact_root_rejects_external_folder();
tests.checkpoint_external = test_checkpoint_root_remains_external();
tests.existing_calibration_blocks = ...
    test_existing_calibration_artifact_blocks_formal_freeze();
tests.existing_validation_blocks = ...
    test_existing_validation_artifact_blocks_formal_finalize();
tests.validation_calibration_immutable = ...
    test_calibration_sha_unchanged_after_validation();
tests.public_validation_committed = ...
    test_public_validation_wrapper_requires_committed_thresholds();
tests.public_finalizer_reloads = ...
    test_public_finalizer_reloads_thresholds_from_disk();
tests.stage8_1b_lifecycle = test_stage8_1b_two_commit_lifecycle(step_dir);
tests.artifact_registry = test_stage8_1_artifact_registry();
tests.manifest = test_stage8_1_manifest_no_self_reference();
tests.writer = test_stage8_1_writer_determinism();
tests.no_stage8_2 = test_stage8_1_no_stage8_2_execution(step_dir);
tests.stage7_1_frozen = verify_stage7_1_frozen_evidence(package_dir);
tests.stage6_frozen = verify_stage6_frozen_evidence(package_dir);
tests.stage5_frozen = verify_stage5_frozen_results(package_dir);
tests.step11_frozen = verify_step11_frozen_results(package_dir);

[analyzer_count, analyzer_table] = code_analyzer_local(step_dir);
[scope_violation_count, scope_table] = scope_scan_local(step_dir);
[formal_artifact_count, artifact_table] = artifact_scan_local(step_dir);
names = fieldnames(tests);
assertion_count = 0;
all_tests_pass = true;
for test_index = 1:numel(names)
    value = tests.(names{test_index});
    if istable(value) && ismember('pass_flag', value.Properties.VariableNames)
        assertion_count = assertion_count + height(value);
        all_tests_pass = all_tests_pass && all(value.pass_flag);
    end
end
technical_pass = all_tests_pass && analyzer_count == 0 && ...
    scope_violation_count == 0 && formal_artifact_count == 0;
summary = table(assertion_count, analyzer_count, scope_violation_count, ...
    formal_artifact_count, all_tests_pass, technical_pass, ...
    string(registry.registry_hash), ...
    string(calibration.calibration_plan_hash), ...
    'VariableNames', {'assertion_count','analyzer_count', ...
    'scope_violation_count','formal_artifact_count','all_tests_pass', ...
    'technical_pass','measurement_registry_hash', ...
    'calibration_plan_hash'});
fprintf(['Stage8.1A code-only tests: %d assertions; analyzer/scope/artifact ', ...
    'violations %d/%d/%d; PASS=%d.\n'], assertion_count, analyzer_count, ...
    scope_violation_count, formal_artifact_count, technical_pass);
if analyzer_count > 0, disp(analyzer_table); end
if scope_violation_count > 0, disp(scope_table); end
if formal_artifact_count > 0, disp(artifact_table); end
assert(technical_pass, 'run_stage8_1a_contract_unit_tests:Failed', ...
    'At least one Stage8.1A code-only gate failed.');
report = struct('summary', summary, 'tests', tests, ...
    'code_analyzer_table', analyzer_table, 'scope_table', scope_table, ...
    'artifact_table', artifact_table, 'repo_dir', repo_dir);
clear path_cleanup
end

function [count, table_out] = code_analyzer_local(step_dir)
files = dir(fullfile(step_dir, '**', '*.m'));
messages_by_file = cell(numel(files), 1);
for file_index = 1:numel(files)
    messages_by_file{file_index} = checkcode( ...
        fullfile(files(file_index).folder, files(file_index).name), '-id');
end
count = sum(cellfun(@numel, messages_by_file));
if count == 0
    table_out = table();
    return;
end
file_column = strings(count, 1);
line_column = zeros(count, 1);
id_column = strings(count, 1);
message_column = strings(count, 1);
row_index = 0;
for file_index = 1:numel(files)
    path_now = fullfile(files(file_index).folder, files(file_index).name);
    messages = messages_by_file{file_index};
    for message_index = 1:numel(messages)
        row_index = row_index + 1;
        file_column(row_index) = string(path_now);
        line_column(row_index) = messages(message_index).line;
        id_column(row_index) = string(messages(message_index).id);
        message_column(row_index) = string(messages(message_index).message);
    end
end
table_out = table(file_column, line_column, id_column, message_column, ...
    'VariableNames', {'file','line','message_id','message'});
end

function [count, table_out] = scope_scan_local(step_dir)
files = dir(fullfile(step_dir, 'common', '**', '*.m'));
forbidden = ["spatialphasefactor = 2";"fixed ridge";"score_gap"; ...
    "group_unidentifiable";"chi2inv";"truth-dependent"; ...
    "holdout-dependent"];
file_column = strings(numel(files) * numel(forbidden), 1);
token_column = strings(size(file_column));
row_index = 0;
for file_index = 1:numel(files)
    text_now = lower(string(fileread( ...
        fullfile(files(file_index).folder, files(file_index).name))));
    for token_index = 1:numel(forbidden)
        if contains(text_now, forbidden(token_index))
            row_index = row_index + 1;
            file_column(row_index) = string(files(file_index).name);
            token_column(row_index) = forbidden(token_index);
        end
    end
end
count = row_index;
if count == 0
    table_out = table();
else
    table_out = table(file_column(1:count), token_column(1:count), ...
        'VariableNames', {'file','token'});
end
end

function [count, table_out] = artifact_scan_local(step_dir)
roots = ["calibration";"results";"figures"];
paths = strings(0, 1);
for root_index = 1:numel(roots)
    files = dir(fullfile(step_dir, roots(root_index), '**', '*'));
    files = files(~[files.isdir]);
    for file_index = 1:numel(files)
        if ~strcmp(files(file_index).name, '.gitkeep')
            paths(end + 1, 1) = string(fullfile( ...
                files(file_index).folder, files(file_index).name)); %#ok<AGROW>
        end
    end
end
count = numel(paths);
table_out = table(paths, 'VariableNames', {'unexpected_artifact'});
end
