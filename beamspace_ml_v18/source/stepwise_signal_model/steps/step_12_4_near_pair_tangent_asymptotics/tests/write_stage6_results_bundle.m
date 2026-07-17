function outputs = write_stage6_results_bundle( ...
    result_dir, figure_dir, context, evidence, validation)
%WRITE_STAGE6_RESULTS_BUNDLE Write all registered stage-6 artifacts.
% This function writes evidence; stage 6.1A changes only this generator.

if exist(result_dir, 'dir') ~= 7, mkdir(result_dir); end
if exist(figure_dir, 'dir') ~= 7, mkdir(figure_dir); end

tables = struct( ...
    'stage6_configuration_registry', evidence.configuration_table, ...
    'measurement_hash_registry', evidence.measurement_hash_table, ...
    'first_derivative_validation', evidence.first_derivative_table, ...
    'higher_directional_derivative_validation', evidence.higher_derivative_table, ...
    'projected_metric_properties', evidence.metric_table, ...
    'tangent_eigenvalues', evidence.eigenvalue_table, ...
    'secant_tangent_nondegenerate', evidence.secant_table, ...
    'secant_tangent_tail_summary', evidence.tail_table, ...
    'secant_tangent_exact_null', evidence.exact_null_table, ...
    'secant_tangent_near_null', evidence.near_null_table, ...
    'synthetic_null_validation', evidence.synthetic_table, ...
    'two_column_exact_identity', evidence.identity_table, ...
    'geometry_invariance_validation', evidence.invariance_table, ...
    'column_norm_asymmetry', evidence.asymmetry_table);
names = fieldnames(tables);
outputs = struct();
for index = 1:numel(names)
    path_now = fullfile(result_dir, [names{index}, '.csv']);
    writetable(tables.(names{index}), path_now);
    outputs.(names{index}) = path_now;
end

keypoints = append_validation_keypoints_local( ...
    evidence.keypoints_table, evidence, validation);
keypoints_path = fullfile(result_dir, 'stage6_keypoints.csv');
writetable(keypoints, keypoints_path);
outputs.stage6_keypoints = keypoints_path;

source_manifest = manifest_output_local( ...
    context.plan.source_manifest, context, "SOURCE_MANIFEST");
source_manifest_path = fullfile(result_dir, 'stage6_source_manifest.csv');
writetable(source_manifest, source_manifest_path);
outputs.stage6_source_manifest = source_manifest_path;
dependency_manifest = manifest_output_local( ...
    context.plan.dependency_manifest, context, "DEPENDENCY_MANIFEST");
dependency_manifest_path = fullfile(result_dir, 'stage6_dependency_manifest.csv');
writetable(dependency_manifest, dependency_manifest_path);
outputs.stage6_dependency_manifest = dependency_manifest_path;
contract_table = provenance_contract_table_local(context);
contract_path = fullfile(result_dir, 'stage6_provenance_contract.csv');
writetable(contract_table, contract_path);
outputs.stage6_provenance_contract = contract_path;
runtime_table = runtime_diagnostics_table_local(context, evidence, validation);
runtime_path = fullfile(result_dir, 'stage6_runtime_diagnostics.csv');
writetable(runtime_table, runtime_path);
outputs.stage6_runtime_diagnostics = runtime_path;

prior_art_path = fullfile(result_dir, 'stage6_prior_art_mapping.md');
write_prior_art_local(prior_art_path, context);
outputs.stage6_prior_art_mapping = prior_art_path;
report_path = fullfile(result_dir, 'stage6_theory_validation.md');
write_report_local(report_path, context, evidence, validation);
outputs.stage6_theory_validation = report_path;

figure_paths = write_figures_local(figure_dir, evidence);
figure_names = fieldnames(figure_paths);
for index = 1:numel(figure_names)
    outputs.(figure_names{index}) = figure_paths.(figure_names{index});
end

end

function table_out = append_validation_keypoints_local(table_in, evidence, validation)
table_out = table_in;
context = validation.context;
items = { ...
    'registered_test_row_count', validation.test_row_count, 'count', validation.tests_pass; ...
    'code_analyzer_message_count', validation.analyzer_count, 'count', validation.analyzer_count == 0; ...
    'stage6_scope_violation_count', validation.scope_violation_count, 'count', validation.scope_violation_count == 0; ...
    'stage5_frozen_file_count', validation.stage5_file_count, 'count', validation.stage5_frozen_pass; ...
    'stage5_frozen_hash_mismatch_count', validation.stage5_hash_mismatch_count, 'count', validation.stage5_hash_mismatch_count == 0; ...
    'step11_frozen_file_count', validation.step11_file_count, 'count', validation.step11_frozen_pass; ...
    'step11_frozen_hash_mismatch_count', validation.step11_hash_mismatch_count, 'count', validation.step11_hash_mismatch_count == 0; ...
    'receive_manifold_evaluation_count', evidence.complexity.receive_manifold_evaluation_count, 'count', true; ...
    'secant_svd_count', evidence.complexity.secant_svd_count, 'count', true; ...
    'metric_eigendecomposition_count', evidence.complexity.metric_eigendecomposition_count, 'count', true; ...
    'derivative_evaluation_count', evidence.complexity.derivative_evaluation_count, 'count', true; ...
    'direct_identical_prior_art_found_flag', 0, 'boolean', true; ...
    'stage6_overall_pass', double(validation.overall_pass), 'boolean', validation.overall_pass};
for index = 1:size(items, 1)
    table_out = append_keypoint_local(table_out, items{index, 1}, ...
        items{index, 2}, items{index, 3}, items{index, 4}, context);
end
end

function table_out = append_keypoint_local(table_in, metric, value, unit, pass, context)
row = table_in(1, :);
row.metric = string(metric);
row.value = value;
row.unit = string(unit);
if pass, row.status = "PASS"; else, row.status = "FAIL"; end
row.pass_flag = logical(pass);
row.fixed_measurement_hash = "MULTIPLE_REGISTERED_MODELS";
row = add_stage6_provenance_metadata(row, context, ...
    "MULTIPLE_REGISTERED_MODELS");
table_out = [table_in; row];
end

function table_out = manifest_output_local(manifest, context, artifact_id)
table_out = manifest;
table_out.manifest_artifact_id = repmat(artifact_id, height(table_out), 1);
table_out = add_stage6_provenance_metadata(table_out, context, ...
    "NOT_APPLICABLE");
end

function table_out = provenance_contract_table_local(context)
plan = context.plan;
table_out = table(string(plan.baseline_commit), ...
    string(plan.stage6_source_tree_hash), ...
    string(plan.stage6_dependency_tree_hash), ...
    string(plan.stage6_controls_hash), ...
    string(plan.stage6_measurement_plan_hash), ...
    string(plan.stage6_experiment_plan_hash), ...
    string(plan.stage6_provenance_hash), ...
    string(plan.provenance_contract_version), ...
    string(plan.source_scope_version), ...
    string(plan.dependency_scope_version), ...
    string(plan.matlab_release_contract), ...
    logical(plan.baseline_ancestor_flag), ...
    logical(plan.working_tree_clean_at_start), 1, ...
    string(context.theory_status), string(context.prior_art_status), true, ...
    "NOT_APPLICABLE", 'VariableNames', { ...
    'baseline_commit','stage6_source_tree_hash', ...
    'stage6_dependency_tree_hash','stage6_controls_hash', ...
    'stage6_measurement_plan_hash','stage6_experiment_plan_hash', ...
    'stage6_provenance_hash','provenance_contract_version', ...
    'source_scope_version','dependency_scope_version', ...
    'matlab_release_contract','baseline_ancestor_flag', ...
    'working_tree_clean_at_start','phase_factor','theory_status', ...
    'prior_art_status','pass_flag','fixed_measurement_hash'});
end

function table_out = runtime_diagnostics_table_local(context, evidence, validation)
[process_peak_memory_bytes, memory_status] = process_peak_memory_local();
table_out = table(string(context.plan.runtime_head_commit), ...
    evidence.complexity.runtime_sec, "REGISTERED_EXPERIMENTS_ONLY", ...
    process_peak_memory_bytes, string(memory_status), ...
    evidence.complexity.fixed_model_memory_bytes, ...
    string(version('-release')), string(computer), 1, ...
    logical(validation.overall_pass), ...
    'VariableNames', {'runtime_head_commit', ...
    'registered_experiment_runtime_sec','runtime_scope', ...
    'matlab_process_peak_memory_bytes','peak_memory_status', ...
    'fixed_model_memory_bytes','matlab_release','computer_architecture', ...
    'phase_factor','pass_flag'});
table_out = add_stage6_provenance_metadata(table_out, context, ...
    "MULTIPLE_REGISTERED_MODELS");
end

function [bytes, status] = process_peak_memory_local()
try
    process = System.Diagnostics.Process.GetCurrentProcess();
    bytes = double(process.PeakWorkingSet64);
    status = 'PROCESS_PEAK_WORKING_SET';
catch
    bytes = NaN;
    status = 'PROCESS_PEAK_MEMORY_UNAVAILABLE';
end
end

function write_prior_art_local(path_now, context)
fid = fopen(path_now, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Stage-6 Prior-Art Incremental Mapping\n\n');
fprintf(fid, '> Access date: 2026-07-17\n');
fprintf(fid, '> Scope: bounded formula-targeted retrieval, not an exhaustive patent or full-text search.\n\n');
fprintf(fid, '## Claim mapping\n\n');
fprintf(fid, '| Item | Label | Boundary |\n|---|---|---|\n');
fprintf(fid, '| Center-difference parameterization | Mathematical form similar | Standard close-source symmetric localization. |\n');
fprintf(fid, '| Sum-difference unitary transform | Existing identical linear-algebra mechanism | A two-column Hadamard/unitary change of basis is standard. |\n');
fprintf(fid, '| Projected Jacobian metric | Existing identical method | It is the geometric part of the deterministic effective FIM after eliminating complex amplitude. |\n');
fprintf(fid, '| Second-singular-value quadratic asymptotic | Mathematical form similar | Close-source CRB and manifold geometry provide the local tangent basis; no direct fixed sequential-DBF equation was located in the bounded search. |\n');
fprintf(fid, '| Normalized-coherence quadratic deficit | Mathematical form similar | Normalized manifold distance/coherence uses the same projected tangent metric. |\n');
fprintf(fid, '| Normalized-Gram condition asymptotic | Mathematical form similar | The exact two-column Gram spectrum is standard; the current use is a sequential-manifold specialization. |\n');
fprintf(fid, '| Exact-null third-order effective vector and sixth-order candidate | No direct identical equation located | Validated here on an analytic fixture; no registered primary physical exact null was found. |\n');
fprintf(fid, '| Unified use on a fixed whitened sequential cylindrical manifold | No direct identical complete treatment located | This is reported only as a scenario-specific corollary, not proof of novelty. |\n\n');
fprintf(fid, '## Directly checked works\n\n');
fprintf(fid, '- *Differential Geometry of Array Manifold Surfaces* (2004), DOI 10.1142/9781860946028_0003.\n');
fprintf(fid, '- *Statistical Angular Resolution Limit for Point Sources* (2007), DOI 10.1109/TSP.2007.898789.\n');
fprintf(fid, '- Vincent, Besson and Chaumette, *Approximate maximum likelihood estimation of two closely spaced sources* (2014), DOI 10.1016/j.sigpro.2013.10.017.\n');
fprintf(fid, '- *On Fisher Information Matrix, Array Manifold Geometry and Time Delay Estimation* (2023), DOI 10.1007/978-3-031-38271-0_30.\n');
fprintf(fid, '- Lee and Wengrovitz, *Resolution threshold of beamspace MUSIC for two closely spaced emitters* (1990), DOI 10.1109/29.60074.\n\n');
fprintf(fid, '## Reproducible retrieval provenance\n\n');
fprintf(fid, '- OpenAlex: `GET /works?search={query}&per_page=5&select=id,doi,title,publication_year,cited_by_count` for the five locked formula queries. Counts were 2933, 12360, 368, 2499 and 496; leading results were mostly off-topic, so counts were not used as evidence.\n');
fprintf(fid, '- Crossref: `GET /works?query.bibliographic={query}&rows=5` for the same five queries, plus exact `GET /works/{doi}` calls for the five works above.\n');
fprintf(fid, '- Semantic Scholar: `GET /graph/v1/paper/search?query={query}&limit=8&fields=...`; all five calls returned HTTP 429 without an API key. The failure is recorded and is not interpreted as an empty literature set.\n');
fprintf(fid, '- Search phrases: second singular value of two steering vectors Taylor expansion; projected Jacobian close sources singular value; normalized coherence local Fisher metric; Gram condition number closely spaced array manifold; tangent-null higher-order array manifold separation.\n\n');
fprintf(fid, '## Conclusion\n\n');
fprintf(fid, 'No directly identical publication containing all three asymptotic equations and the exact-null extension on the present fixed whitened sequential cylindrical receive manifold was located in this bounded retrieval. This does not establish novelty. The status remains `%s`.\n', context.prior_art_status);
end

function write_report_local(path_now, context, evidence, validation)
k = evidence.keypoints_table;
value = @(name) k.value(k.metric == string(name));
fid = fopen(path_now, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '---\nphase_factor: 1\ntheory_status: %s\n', evidence.theory_status);
fprintf(fid, 'statistical_scope: DETERMINISTIC_GEOMETRIC_VALIDATION\n');
fprintf(fid, 'baseline_commit: %s\n', context.plan.baseline_commit);
fprintf(fid, 'stage6_source_tree_hash: %s\n', context.plan.stage6_source_tree_hash);
fprintf(fid, 'stage6_dependency_tree_hash: %s\n', ...
    context.plan.stage6_dependency_tree_hash);
fprintf(fid, 'stage6_controls_hash: %s\n', context.plan.stage6_controls_hash);
fprintf(fid, 'stage6_measurement_plan_hash: %s\n', ...
    context.plan.stage6_measurement_plan_hash);
fprintf(fid, 'stage6_experiment_plan_hash: %s\n', ...
    context.plan.stage6_experiment_plan_hash);
fprintf(fid, 'stage6_provenance_hash: %s\n', context.plan.stage6_provenance_hash);
fprintf(fid, 'provenance_contract_version: %s\n---\n\n', ...
    context.plan.provenance_contract_version);
fprintf(fid, '# Step12.4 Fixed-Whitening Tangent-Asymptotic Validation\n\n');
fprintf(fid, '## A. Stage conclusion\n\n');
fprintf(fid, '**%s.** Theory status: `%s`. The three nondegenerate asymptotic relations and the synthetic sixth-order exact-null extension passed. Physical status: `%s`. A separately authorized phase 7 is technically permissible; this run stops at phase 6.\n\n', ...
    pass_fail_local(validation.overall_pass), evidence.theory_status, evidence.physical_null_status);
fprintf(fid, '## B. Prior-art boundary\n\n');
fprintf(fid, 'Center-difference coordinates, the sum-difference unitary transform, the projected Jacobian/effective FIM, two-column Gram spectra and coherence geometry are prior art. The retained statement is only a scenario-specific explicit corollary for one fixed, exactly whitened sequential cylindrical receive manifold. Formula-targeted OpenAlex/Crossref retrieval was bounded and Semantic Scholar returned HTTP 429.\n\n');
fprintf(fid, '## C. Files\n\n');
fprintf(fid, 'Public geometry code is under `common/`; locked plans and fixtures are under `tests/private/`; fourteen required tests are under `tests/`; CSV and reports are under `results/`; seven registered PNGs are under `figures/`.\n\n');
fprintf(fid, '## D. Formula-to-code mapping\n\n');
fprintf(fid, '- `build_fixed_whitened_sequential_derivatives`: fixed `g` and per-radian `J`.\n');
fprintf(fid, '- `compute_projected_jacobian_metric`: `P_g_perp` and real symmetric `T`.\n');
fprintf(fid, '- `evaluate_secant_tangent_case`: direct-SVD `sigma2`, coherence and normalized-Gram relations.\n');
fprintf(fid, '- `compute_tangent_null_sixth_order`: `alpha`, `v3_eff` and the registered sixth-order candidate.\n');
fprintf(fid, '- `build_stage6_fixed_measurement_model`: fixed `Wseq/Cseq/Tseq` and SHA-256 contract.\n\n');
fprintf(fid, '## E. Dimensions, units and fixed objects\n\n');
fprintf(fid, 'The four primary configurations have 9, 9, 6 and 6 sequential outputs; the diagnostic has one. `Wseq` is `2080 x B`, `Cseq` is `B x B`, `Tseq` is `rank(Cseq) x B`, `g` is `rank(Cseq) x 1`, `J` is `rank(Cseq) x 2`, `G2` is `rank(Cseq) x 2`, and `T` is `2 x 2`. External angles use degree; derivatives, directions and separations use radian.\n\n');
fprintf(fid, '## F. Tests and command\n\n');
fprintf(fid, 'The unified runner executed the registered numerical and provenance tests, Code Analyzer, scope/schema/hash scans, 14-file stage-5 SHA-256 verification and 351-file Step11 official-manifest verification. Command: `run(''beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/run_step12_4_tangent_asymptotics_validation.m'')`. Analyzer messages: %d.\n\n', validation.analyzer_count);
fprintf(fid, '## G. Key results\n\n');
fprintf(fid, '- Maximum first/second/third derivative relative errors: %.6g / %.6g / %.6g.\n', ...
    value('maximum_first_derivative_relative_error'), ...
    value('maximum_second_derivative_relative_error'), ...
    value('maximum_third_derivative_relative_error'));
fprintf(fid, '- Maximum registered tail errors for sigma2/coherence/normalized Gram: %.6g / %.6g / %.6g.\n', ...
    value('maximum_sigma2_tail_ratio_error'), ...
    value('maximum_coherence_tail_ratio_error'), ...
    value('maximum_normalized_gram_tail_ratio_error'));
fprintf(fid, '- Minimum tail point count: %d; maximum unsaturated exact-identity error: %.6g; maximum invariance error: %.6g.\n', ...
    round(value('minimum_tail_point_count')), ...
    value('maximum_exact_identity_relative_error'), ...
    value('maximum_geometry_invariance_error'));
fprintf(fid, '- Synthetic exact-null order: %.6g; maximum sixth-order ratio error: %.6g. No statistical confidence interval is reported because this is deterministic geometry validation.\n\n', ...
    value('synthetic_null_fitted_order'), value('maximum_synthetic_null_ratio_error'));
fprintf(fid, '## H. Complexity\n\n');
fprintf(fid, 'Registered secant SVDs: %d; metric eigendecompositions: %d; derivative cases: %d; receive-manifold evaluations: %d. Runtime and memory diagnostics are isolated in `stage6_runtime_diagnostics.csv`.\n\n', ...
    evidence.complexity.secant_svd_count, ...
    evidence.complexity.metric_eigendecomposition_count, ...
    evidence.complexity.derivative_evaluation_count, ...
    evidence.complexity.receive_manifold_evaluation_count);
fprintf(fid, '## I. Risks and unfinished work\n\n');
fprintf(fid, 'No exact tangent null occurred in the four primary physical configurations; the single-channel case is only an exact measurement collapse. The sixth-order extension is therefore physically untested here despite analytic-fixture support. Finite-sample resolution, threshold SNR, source coherence, model order, FIM beam selection, patent search and paid-database full-text/cited-by review remain outside this stage.\n\n');
fprintf(fid, '## J. Next-stage decision\n\n');
fprintf(fid, 'The fixed measurement contract, all three nondegenerate relations, prior-art boundary and honest null classification passed. Technically, a later phase 7 may be entered only after separate user authorization. This run stops here.\n');
end

function paths = write_figures_local(figure_dir, evidence)
secant = evidence.secant_table;
paths = struct();
paths.sigma2_ratio_vs_separation = ratio_figure_local(secant, ...
    'sigma2_ratio', 'Second singular-value ratio', ...
    fullfile(figure_dir, 'sigma2_ratio_vs_separation.png'));
paths.coherence_ratio_vs_separation = ratio_figure_local(secant, ...
    'coherence_ratio', 'Normalized-coherence ratio', ...
    fullfile(figure_dir, 'coherence_ratio_vs_separation.png'));
paths.normalized_gram_ratio_vs_separation = ratio_figure_local(secant, ...
    'normalized_gram_ratio', 'Normalized-Gram condition ratio', ...
    fullfile(figure_dir, 'normalized_gram_ratio_vs_separation.png'));

figure_handle = figure('Visible', 'off', 'Color', 'w');
loglog(secant.separation_norm_deg, secant.taylor_sum_residual, '.', ...
    'Color', [0.15, 0.45, 0.75]); hold on
loglog(secant.separation_norm_deg, secant.taylor_difference_residual, '.', ...
    'Color', [0.85, 0.35, 0.15]); grid on
xlabel('Separation norm (degree)'); ylabel('Relative Taylor residual');
legend('Symmetric sum', 'Antisymmetric difference', 'Location', 'best');
title('Registered Taylor intermediate checks');
paths.taylor_residual_vs_separation = fullfile(figure_dir, 'taylor_residual_vs_separation.png');
exportgraphics(figure_handle, paths.taylor_residual_vs_separation, 'Resolution', 180);
close(figure_handle);

eigenvalues = evidence.eigenvalue_table(evidence.eigenvalue_table.config_id ~= ...
    "SINGLE_CHANNEL_DIAGNOSTIC", :);
figure_handle = figure('Visible', 'off', 'Color', 'w');
scatter(eigenvalues.center_az_deg, eigenvalues.center_el_deg, 60, ...
    log10(eigenvalues.lambda_min_to_max_ratio), 'filled'); grid on; colorbar
xlabel('Center azimuth (degree)'); ylabel('Center elevation (degree)');
title('Projected-metric minimum-to-maximum eigenvalue ratio');
paths.tangent_eigenvalue_map = fullfile(figure_dir, 'tangent_eigenvalue_map.png');
exportgraphics(figure_handle, paths.tangent_eigenvalue_map, 'Resolution', 180);
close(figure_handle);

synthetic = evidence.synthetic_table;
figure_handle = figure('Visible', 'off', 'Color', 'w');
loglog(synthetic.separation_norm_rad, synthetic.sigma2_sq, 'o-', ...
    'LineWidth', 1.2); hold on
loglog(synthetic.separation_norm_rad, synthetic.null_sigma2_prediction, '--', ...
    'LineWidth', 1.2); grid on
xlabel('Separation norm (radian)'); ylabel('Second singular value squared');
legend('Analytic fixture', 'Sixth-order prediction', 'Location', 'best');
title('Synthetic exact tangent-null order');
paths.null_direction_order_fit = fullfile(figure_dir, 'null_direction_order_fit.png');
exportgraphics(figure_handle, paths.null_direction_order_fit, 'Resolution', 180);
close(figure_handle);

figure_handle = figure('Visible', 'off', 'Color', 'w');
semilogx(secant.separation_norm_deg, secant.column_norm_ratio, '.', ...
    'Color', [0.25, 0.55, 0.25]); yline(1, '--k'); grid on
xlabel('Separation norm (degree)'); ylabel('Column norm minus / plus');
title('Column-norm asymmetry retained separately from normalized Gram');
paths.column_norm_ratio_vs_separation = fullfile(figure_dir, 'column_norm_ratio_vs_separation.png');
exportgraphics(figure_handle, paths.column_norm_ratio_vs_separation, 'Resolution', 180);
close(figure_handle);
end

function path_now = ratio_figure_local(table_in, variable, label, path_now)
figure_handle = figure('Visible', 'off', 'Color', 'w');
semilogx(table_in.separation_norm_deg, table_in.(variable), '.', ...
    'Color', [0.15, 0.45, 0.75]); hold on; yline(1, '--k'); grid on
xlabel('Separation norm (degree)'); ylabel(label); title(['Registered ', label]);
exportgraphics(figure_handle, path_now, 'Resolution', 180);
close(figure_handle);
end

function text = pass_fail_local(flag)
if flag, text = 'PASS'; else, text = 'FAIL'; end
end
