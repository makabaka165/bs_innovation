function results = test_stage8_k2_va_applicability_analysis(repo_dir)
%TEST_STAGE8_K2_VA_APPLICABILITY_ANALYSIS Validate the offline closure.

if nargin < 1 || isempty(repo_dir)
    analysis_dir = fileparts(mfilename('fullpath'));
    repo_dir = fileparts(fileparts(fileparts(analysis_dir)));
end
analysis = stage8_k2_va_applicability_analysis(repo_dir, false);
names = [ ...
    "count_contract"; ...
    "shared_trial_hashes"; ...
    "paired_delta_direction"; ...
    "win_tie_loss_fixture"; ...
    "geometry_identity"; ...
    "axis_sign_invariance"; ...
    "fallback_nan_preservation"; ...
    "profile_classification_fixture"; ...
    "interaction_descriptive_only"; ...
    "historical_summary_reconstruction"];
tests = { ...
    @() test_count_contract_local(analysis); ...
    @() test_hash_contract_local(analysis); ...
    @() test_delta_direction_local(analysis); ...
    @test_pair_label_fixture_local; ...
    @test_geometry_identity_local; ...
    @test_axis_sign_invariance_local; ...
    @() test_fallback_nan_local(analysis); ...
    @test_classification_fixture_local; ...
    @test_interaction_local; ...
    @() test_summary_reconstruction_local(analysis)};
passed = false(numel(tests), 1);
message = strings(numel(tests), 1);
for index = 1:numel(tests)
    try
        tests{index}();
        passed(index) = true;
        message(index) = "PASS";
    catch exception
        message(index) = string(exception.message);
    end
end
results = table(names, passed, message, ...
    'VariableNames', {'test_name', 'pass', 'message'});
disp(results);
if ~all(passed)
    error('test_stage8_k2_va_applicability_analysis:Failure', ...
        '%d applicability analysis tests failed.', nnz(~passed));
end
end

function test_count_contract_local(analysis)
assert(analysis.integrity.method_rows == 288);
assert(analysis.integrity.unique_trials == 72);
assert(analysis.integrity.diagnostic_rows == 72);
assert(height(analysis.paired_trials) == 72);
end

function test_hash_contract_local(analysis)
assert(analysis.integrity.method_contract_ok);
assert(analysis.integrity.hash_contract_ok);
assert(analysis.integrity.truth_isolation_ok);
end

function test_delta_direction_local(analysis)
rows = analysis.paired_trials;
expected = rows.anchored_joint_RMSE_deg - rows.tangent_joint_RMSE_deg;
assert(max(abs(rows.delta_joint_RMSE_deg - expected)) < 1e-14);
assert(all(rows.pair_label(rows.delta_joint_RMSE_deg < -1e-6) == "WIN"));
assert(all(rows.pair_label(rows.delta_joint_RMSE_deg > 1e-6) == "LOSS"));
end

function test_pair_label_fixture_local()
labels = stage8_k2_va_pair_label([-2e-6; -1e-7; 2e-6], 1e-6);
assert(isequal(labels, ["WIN"; "TIE"; "LOSS"]));
end

function test_geometry_identity_local()
true_center = [1.0, 2.0];
k1_center = [0.8, 2.1];
axis_hat = [0.6, 0.8];
metrics = stage8_k2_va_geometry_metrics( ...
    true_center, k1_center, axis_hat, 0.2, 0.05);
reconstructed = metrics.alpha_true_deg * axis_hat + ...
    metrics.perpendicular_offset_deg;
assert(norm(reconstructed - (true_center - k1_center)) < 1e-14);
assert(abs(dot(metrics.perpendicular_offset_deg, axis_hat)) < 1e-14);
end

function test_axis_sign_invariance_local()
true_center = [1.0, 2.0];
k1_center = [0.8, 2.1];
axis_hat = [0.6, 0.8];
positive = stage8_k2_va_geometry_metrics( ...
    true_center, k1_center, axis_hat, 0.2, 0.05);
negative = stage8_k2_va_geometry_metrics( ...
    true_center, k1_center, -axis_hat, 0.2, -0.05);
assert(abs(positive.b_parallel_abs - negative.b_parallel_abs) < 1e-14);
assert(abs(positive.b_perp - negative.b_perp) < 1e-14);
end

function test_fallback_nan_local(analysis)
rows = analysis.paired_trials;
invalid_fallback = rows.fallback_flag & ~rows.raw_candidate_valid;
assert(nnz(invalid_fallback) == 8);
assert(all(isnan(rows.selected_alpha_deg(invalid_fallback))));
end

function test_classification_fixture_local()
metrics = fixture_metrics_local();
assert(stage8_k2_va_applicability_classify(metrics, true) == ...
    "SUPPORTED_ENDPOINT_AND_SEPARATION");
metrics.p90_joint_anchored = 2.5;
assert(stage8_k2_va_applicability_classify(metrics, true) == ...
    "MEDIAN_GAIN_BUT_TAIL_UNSTABLE");
metrics = fixture_metrics_local();
metrics.median_joint_anchored = 1.2;
metrics.p90_joint_anchored = 2.2;
metrics.median_rho_anchored = 0.5;
metrics.median_vector_anchored = 0.5;
assert(stage8_k2_va_applicability_classify(metrics, true) == ...
    "SEPARATION_STRUCTURE_ONLY");
metrics.median_rho_anchored = 2;
metrics.median_vector_anchored = 2;
assert(stage8_k2_va_applicability_classify(metrics, true) == ...
    "NOT_SUPPORTED");
end

function test_interaction_local()
metrics = fixture_metrics_local();
assert(stage8_k2_va_applicability_classify(metrics, false) == ...
    "DESCRIPTIVE_ONLY");
end

function test_summary_reconstruction_local(analysis)
assert(analysis.integrity.summary_reconstruction_ok);
assert(analysis.integrity.summary_reconstruction_max_abs_error <= 1e-10);
end

function metrics = fixture_metrics_local()
metrics = struct( ...
    'N', 18, 'anchored_valid_count', 18, ...
    'median_joint_tangent', 1, 'median_joint_anchored', 0.8, ...
    'p90_joint_tangent', 2, 'p90_joint_anchored', 1.5, ...
    'wins', 10, 'losses', 8, 'median_rho_tangent', 1, ...
    'median_rho_anchored', 0.8, 'median_vector_tangent', 1, ...
    'median_vector_anchored', 0.8);
end
