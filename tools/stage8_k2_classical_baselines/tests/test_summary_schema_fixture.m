function result = test_summary_schema_fixture()
%TEST_SUMMARY_SCHEMA_FIXTURE Exercise all formal table/report writers.

test_dir = fileparts(mfilename('fullpath'));
repo_dir = fileparts(fileparts(fileparts(test_dir)));
scope = stage8_k2_cb_add_paths(repo_dir); %#ok<NASGU>
context = stage8_k2_cb_build_context(repo_dir);
registry = stage8_k2_cb_build_registry(context);
frozen = stage8_k2_cb_frozen_rows(context, registry);
tangent = frozen(frozen.method_id == "TANGENT_PROFILE_SAFE", :);

beam = tangent;
beam.method_id(:) = "FULL4D_BEAMSPACE_CML_MULTISTART";
beam.method_source(:) = "SCHEMA_FIXTURE";
beam.coarse_candidate_count(:) = 210;
beam.continuous_start_count(:) = 6;
element = beam(beam.L == 4, :);
element.method_id(:) = "FULL4D_ELEMENT_CML_MULTISTART";

beam_music = tangent;
beam_music.method_id(:) = "BEAMSPACE_MUSIC_K2";
beam_music.method_source(:) = "SCHEMA_FIXTURE";
element_music = beam_music;
element_music.method_id(:) = "ELEMENT_MUSIC_K2";
not_applicable = beam_music.L == 1;
beam_music = mark_l1_local(beam_music, not_applicable);
element_music = mark_l1_local(element_music, not_applicable);
rows = [frozen; beam; element; beam_music; element_music];

temporary_repo = tempname;
runtime_root = fullfile(temporary_repo, 'runtime');
mkdir(fullfile(temporary_repo, 'innovation-mining'));
mkdir(runtime_root);
cleanup = onCleanup(@() cleanup_local(temporary_repo));
resources = struct('grid_point_count', 19521);
output = stage8_k2_cb_summarize(rows, registry, resources, ...
    temporary_repo, runtime_root);
assert(output.integrity.experiment_integrity_ok && ...
    height(output.rows) == 456 && height(output.complexity) == 7 && ...
    isfile(output.runtime_paths.report) && ...
    isfile(output.runtime_paths.trials) && ...
    isfile(output.runtime_paths.summary) && ...
    isfile(output.runtime_paths.profile_summary) && ...
    isfile(output.runtime_paths.applicability) && ...
    isfile(output.runtime_paths.complexity), ...
    'test_summary_schema_fixture:Output', ...
    'The complete formal summary schema was not materialized.');
result = struct('pass', true, 'row_count', height(output.rows), ...
    'summary_row_count', height(output.summary));
fprintf('test_summary_schema_fixture PASS rows=456\n');
clear cleanup
end

function rows = mark_l1_local(rows, selected)
rows.applicable(selected) = false;
rows.applicability_status(selected) = ...
    "NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK";
rows.fit_valid(selected) = false;
rows.fit_status(selected) = ...
    "NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK";
metric_names = {'joint_RMSE_deg','azimuth_RMSE_deg', ...
    'elevation_RMSE_deg','center_error_deg','axis_error_deg', ...
    'separation_hat_deg','separation_error_deg', ...
    'separation_vector_error_deg'};
for index = 1:numel(metric_names)
    rows.(metric_names{index})(selected) = NaN;
end
end

function cleanup_local(path_now)
if isfolder(path_now)
    rmdir(path_now, 's');
end
end
