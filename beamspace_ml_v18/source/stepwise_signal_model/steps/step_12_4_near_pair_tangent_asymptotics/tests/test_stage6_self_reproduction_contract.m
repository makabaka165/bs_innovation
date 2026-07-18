function table_out = test_stage6_self_reproduction_contract()
%TEST_STAGE6_SELF_REPRODUCTION_CONTRACT Verify independent snapshot gates.

root = tempname;
mkdir(root);
cleanup = onCleanup(@() rmdir(root, 's'));
base_dir = fullfile(root, 'base');
first_dir = fullfile(root, 'first');
second_dir = fullfile(root, 'second');
mkdir(base_dir);
registry = stage6_required_artifact_registry();
contract = build_stage6_reproduction_comparison_contract();
write_snapshot_local(base_dir, registry, contract);

[baseline_pass, baseline_checks] = scenario_local('runtime');
[numeric_pass, numeric_checks] = scenario_local('numeric');
[source_pass, source_checks] = scenario_local('source');
[theory_pass, theory_checks] = scenario_local('theory');
[png_pass, png_checks] = scenario_local('png');
[comparison_pass, comparison_checks] = scenario_local('comparison');

case_id = ["RUNTIME_DIFFERENCE_PASSES"; ...
    "DETERMINISTIC_CSV_DIFFERENCE_FAILS"; ...
    "SOURCE_TREE_HASH_DIFFERENCE_FAILS"; ...
    "THEORY_STATUS_DIFFERENCE_FAILS"; ...
    "PNG_BYTES_DIFFERENCE_PASSES"; ...
    "COMPARISON_DIFFERENCE_FAILS"; ...
    "NUMERIC_DIAGNOSTIC_EXPOSED"; "SOURCE_DIAGNOSTIC_EXPOSED"; ...
    "THEORY_DIAGNOSTIC_EXPOSED"; "BUNDLE_DIAGNOSTIC_EXPOSED"];
pass_flag = [baseline_pass; ~numeric_pass; ~source_pass; ~theory_pass; ...
    png_pass; ~comparison_pass; ...
    failed_check_local(numeric_checks, 'numeric_evidence_match'); ...
    failed_check_local(source_checks, 'source_tree_hash_match'); ...
    failed_check_local(theory_checks, 'theory_status_match'); ...
    failed_check_local(comparison_checks, ...
    'deterministic_bundle_hash_match') && any( ...
    startsWith(comparison_checks.check_id, ...
    "deterministic_artifact_hash:results/stage6_reproduction_comparison.csv") & ...
    ~comparison_checks.pass_flag)];
pass_flag = logical(pass_flag);
table_out = table(case_id, pass_flag);
if ~all(table_out.pass_flag)
    disp(table_out(~table_out.pass_flag, :));
    if ~baseline_pass
        disp(baseline_checks(~baseline_checks.pass_flag, :));
    end
    if ~png_pass
        disp(png_checks(~png_checks.pass_flag, :));
    end
end
assert(all(table_out.pass_flag), ...
    'test_stage6_self_reproduction_contract:Failed', ...
    'The self-reproduction contract failed a synthetic case.');

    function [pass, checks] = scenario_local(kind)
        if exist(first_dir, 'dir') == 7, rmdir(first_dir, 's'); end
        if exist(second_dir, 'dir') == 7, rmdir(second_dir, 's'); end
        copyfile(base_dir, first_dir);
        copyfile(base_dir, second_dir);
        mutate_local(second_dir, kind);
        [checks, summary] = verify_stage6_self_reproduction( ...
            first_dir, second_dir, registry, ...
            struct('comparison_contract', contract));
        pass = summary.pass_flag(1);
        if ~pass && ismember(kind, {'runtime','png'})
            [comparison_debug, ~] = compare_stage6_evidence_directories( ...
                first_dir, second_dir, contract, struct());
            disp(comparison_debug(~comparison_debug.pass_flag, :));
        end
    end
end

function write_snapshot_local(root, registry, contract)
for index = 1:height(contract)
    table_now = comparison_fixture_local(contract(index, :));
    write_table_local(root, contract.relative_path(index), table_now);
end
provenance = table("BASELINE", "SOURCE_HASH", "DEPENDENCY_HASH", ...
    "CONTROLS_HASH", "MEASUREMENT_HASH", "EXPERIMENT_HASH", ...
    "PROVENANCE_HASH", true, true, 1, true, 'VariableNames', { ...
    'baseline_commit','stage6_source_tree_hash','stage6_dependency_tree_hash', ...
    'stage6_controls_hash','stage6_measurement_plan_hash', ...
    'stage6_experiment_plan_hash','stage6_provenance_hash', ...
    'baseline_ancestor_flag','working_tree_clean_at_start', ...
    'phase_factor','pass_flag'});
write_table_local(root, 'results/stage6_provenance_contract.csv', provenance);
manifest_table = table("path.m", "100644", "BLOB", true, ...
    'VariableNames', {'relative_path','git_mode','git_blob_hash','pass_flag'});
write_table_local(root, 'results/stage6_source_manifest.csv', manifest_table);
write_table_local(root, 'results/stage6_dependency_manifest.csv', manifest_table);
write_text_local(root, 'results/stage6_prior_art_mapping.md', 'prior art');
write_text_local(root, 'results/stage6_theory_validation.md', 'theory report');
write_text_local(root, 'results/stage6_runtime_diagnostics.csv', ...
    'runtime_head_commit,pass_flag\nRUNTIME_A,1\n');
write_text_local(root, 'results/stage6_reproduction_comparison.csv', ...
    'artifact_id,pass_flag\ncomparison,1\n');
for index = 1:height(registry)
    if registry.artifact_type(index) == "PNG"
        write_text_local(root, registry.relative_path(index), ...
            char("PNG_" + registry.artifact_id(index)));
    end
end
end

function table_out = comparison_fixture_local(contract_row)
keys = string(contract_row.key_columns{1});
table_out = table();
for index = 1:numel(keys)
    name = char(keys(index));
    if contains(keys(index), "deg") || contains(keys(index), "rad")
        table_out.(name) = 1;
    else
        table_out.(name) = "KEY";
    end
end
table_out.measurement_value = 1;
table_out.fixed_measurement_hash = "MEASUREMENT_IDENTITY";
table_out.phase_factor = 1;
table_out.pass_flag = true;
table_out.theory_status = "THEORY_OK";
table_out.prior_art_status = "PRIOR_ART_BOUNDED";
if contract_row.artifact_id == "stage6_configuration_registry"
    table_out.global_beam_indices = "az=1;el=1";
end
if contract_row.artifact_id == "stage6_keypoints"
    table_out = keypoints_fixture_local();
end
end

function table_out = keypoints_fixture_local()
metric = ["stage6_overall_pass"; "stage5_frozen_file_count"; ...
    "stage5_frozen_hash_mismatch_count"; "step11_frozen_file_count"; ...
    "step11_frozen_hash_mismatch_count"; "numeric_metric"];
value = [1; 14; 0; 351; 0; 1];
unit = repmat("count", 6, 1);
status = repmat("PASS", 6, 1);
pass_flag = true(6, 1);
fixed_measurement_hash = repmat("MEASUREMENT_IDENTITY", 6, 1);
theory_status_detail = repmat("THEORY_OK", 6, 1);
physical_null_status = repmat("NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND", 6, 1);
phase_factor = ones(6, 1);
theory_status = repmat("THEORY_OK", 6, 1);
prior_art_status = repmat("PRIOR_ART_BOUNDED", 6, 1);
table_out = table(metric, value, unit, status, pass_flag, ...
    fixed_measurement_hash, theory_status_detail, physical_null_status, ...
    phase_factor, theory_status, prior_art_status);
end

function mutate_local(root, kind)
switch kind
    case 'runtime'
        write_text_local(root, 'results/stage6_runtime_diagnostics.csv', ...
            'runtime_head_commit,pass_flag\nRUNTIME_B,1\n');
    case 'numeric'
        path_now = fullfile(root, 'results', 'first_derivative_validation.csv');
        table_now = readtable(path_now, 'TextType', 'string');
        table_now.measurement_value(1) = table_now.measurement_value(1) + 1e-8;
        writetable(table_now, path_now);
    case 'source'
        path_now = fullfile(root, 'results', 'stage6_provenance_contract.csv');
        table_now = readtable(path_now, 'TextType', 'string');
        table_now.stage6_source_tree_hash(1) = "CHANGED_SOURCE_HASH";
        writetable(table_now, path_now);
    case 'theory'
        path_now = fullfile(root, 'results', 'stage6_keypoints.csv');
        table_now = readtable(path_now, 'TextType', 'string');
        table_now.theory_status(:) = "THEORY_CHANGED";
        writetable(table_now, path_now);
    case 'png'
        write_text_local(root, 'figures/tangent_eigenvalue_map.png', 'PNG_CHANGED');
    case 'comparison'
        write_text_local(root, 'results/stage6_reproduction_comparison.csv', ...
            'artifact_id,pass_flag\ncomparison_changed,1\n');
end
end

function flag = failed_check_local(checks, id)
rows = checks.check_id == string(id);
flag = nnz(rows) == 1 && ~checks.pass_flag(rows);
end

function write_table_local(root, relative, table_now)
path_now = fullfile(root, char(relative));
parent = fileparts(path_now);
if exist(parent, 'dir') ~= 7, mkdir(parent); end
writetable(table_now, path_now);
end

function write_text_local(root, relative, text_now)
path_now = fullfile(root, char(relative));
parent = fileparts(path_now);
if exist(parent, 'dir') ~= 7, mkdir(parent); end
fid = fopen(path_now, 'wb');
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, unicode2native(text_now, 'UTF-8'), 'uint8');
end
