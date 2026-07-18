function table_out = test_stage6_evidence_comparator()
%TEST_STAGE6_EVIDENCE_COMPARATOR Exercise key alignment and comparison gates.

root = tempname;
mkdir(root);
cleanup = onCleanup(@() rmdir(root, 's'));
old_dir = fullfile(root, 'old');
new_dir = fullfile(root, 'new');
mkdir(fullfile(old_dir, 'results'));
mkdir(fullfile(new_dir, 'results'));
contract_all = build_stage6_reproduction_comparison_contract();
contract = contract_all(contract_all.artifact_id == ...
    "first_derivative_validation", :);
old = fixture_local();
new = old([2, 1], :);
new.measurement_value(1) = new.measurement_value(1) + 1e-15;
new.baseline_commit = repmat("NEW_PROVENANCE", height(new), 1);
new.fixed_measurement_hash(:) = "NEW_MEASUREMENT_IDENTITY";
write_local(old_dir, old);
write_local(new_dir, new);
[pass_comparison, pass_summary] = compare_stage6_evidence_directories( ...
    old_dir, new_dir, contract, struct());

large = new;
large.measurement_value(1) = large.measurement_value(1) + 1e-8;
write_local(new_dir, large);
[~, large_summary] = compare_stage6_evidence_directories( ...
    old_dir, new_dir, contract, struct());
status_changed = new;
status_changed.theory_status(1) = "CHANGED";
write_local(new_dir, status_changed);
[~, status_summary] = compare_stage6_evidence_directories( ...
    old_dir, new_dir, contract, struct());
missing_key = new(1, :);
write_local(new_dir, missing_key);
[~, missing_summary] = compare_stage6_evidence_directories( ...
    old_dir, new_dir, contract, struct());
duplicate_key = [new; new(1, :)];
write_local(new_dir, duplicate_key);
[~, duplicate_summary] = compare_stage6_evidence_directories( ...
    old_dir, new_dir, contract, struct());
contract_with_registry = contract_all(ismember(contract_all.artifact_id, ...
    ["measurement_hash_registry"; "first_derivative_validation"]), :);
write_local(new_dir, new);
write_measurement_registry_local(old_dir, "OLD_A", "OLD_B");
write_measurement_registry_local(new_dir, ...
    "NEW_MEASUREMENT_IDENTITY", "NEW_MEASUREMENT_IDENTITY");
inconsistent = new;
inconsistent.fixed_measurement_hash(1) = "WRONG_MEASUREMENT_IDENTITY";
write_local(new_dir, inconsistent);
[inconsistent_comparison, inconsistent_summary] = ...
    compare_stage6_evidence_directories(old_dir, new_dir, ...
    contract_with_registry, struct());

case_id = ["ROW_ORDER_INVARIANT"; "NEW_PROVENANCE_COLUMN_IGNORED"; ...
    "ONE_E_MINUS_15_PASSES"; "ONE_E_MINUS_8_FAILS"; ...
    "EXACT_STATUS_CHANGE_FAILS"; "MISSING_KEY_FAILS"; ...
    "DUPLICATE_KEY_FAILS"; "EXPECTED_HASH_CHANGE_MARKED"; ...
    "CURRENT_HASH_INCONSISTENCY_FAILS"];
pass_flag = [ ...
    pass_summary.pass_flag; pass_summary.pass_flag; pass_summary.pass_flag; ...
    ~large_summary.pass_flag && large_summary.numeric_failure_count > 0; ...
    ~status_summary.pass_flag && status_summary.exact_failure_count > 0; ...
    ~missing_summary.pass_flag && missing_summary.row_key_mismatch_count > 0; ...
    ~duplicate_summary.pass_flag && duplicate_summary.row_key_mismatch_count > 0; ...
    any(pass_comparison.expected_identity_change_flag & ...
    pass_comparison.comparison_kind == ...
    "EXPECTED_PROVENANCE_IDENTITY_CHANGE" & pass_comparison.pass_flag); ...
    ~inconsistent_summary.pass_flag && any( ...
    inconsistent_comparison.comparison_kind == ...
    "CURRENT_MEASUREMENT_HASH_CONSISTENCY" & ...
    ~inconsistent_comparison.pass_flag)];
pass_flag = logical(pass_flag);
table_out = table(case_id, pass_flag);
assert(all(table_out.pass_flag), 'test_stage6_evidence_comparator:Failed', ...
    'The evidence comparator failed a synthetic contract case.');
end

function table_out = fixture_local()
config_id = ["A"; "B"];
center_az_deg = [8; 9];
center_el_deg = [10; 11];
finite_difference_step_rad = [1e-6; 1e-6];
measurement_value = [1; 2];
derivative_unit = ["per_radian"; "per_radian"];
fixed_measurement_hash = ["OLD_A"; "OLD_B"];
pass_flag = true(2, 1);
phase_factor = ones(2, 1);
theory_status = repmat("THEORY_OK", 2, 1);
prior_art_status = repmat("PRIOR_ART_BOUNDED", 2, 1);
table_out = table(config_id, center_az_deg, center_el_deg, ...
    finite_difference_step_rad, measurement_value, derivative_unit, ...
    fixed_measurement_hash, pass_flag, phase_factor, theory_status, ...
    prior_art_status);
end

function write_local(root, table_now)
writetable(table_now, fullfile(root, 'results', ...
    'first_derivative_validation.csv'));
end


function write_measurement_registry_local(root, hash_a, hash_b)
config_id = ["A"; "B"];
Wseq_hash = ["W_A"; "W_B"];
Cseq_hash = ["C_A"; "C_B"];
Tseq_hash = ["T_A"; "T_B"];
array_geometry_hash = ["G_A"; "G_B"];
fixed_measurement_hash = [string(hash_a); string(hash_b)];
hash_length = [64; 64];
pass_flag = true(2, 1);
phase_factor = ones(2, 1);
theory_status = repmat("THEORY_OK", 2, 1);
prior_art_status = repmat("PRIOR_ART_BOUNDED", 2, 1);
table_now = table(config_id, Wseq_hash, Cseq_hash, Tseq_hash, ...
    array_geometry_hash, fixed_measurement_hash, hash_length, pass_flag, ...
    phase_factor, theory_status, prior_art_status);
writetable(table_now, fullfile(root, 'results', ...
    'measurement_hash_registry.csv'));
end
