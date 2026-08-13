function result = test_safe_hybrid_selection()
%TEST_SAFE_HYBRID_SELECTION Exercise required H1 fixture branches.

repo = char(java.io.File(fileparts(fileparts(fileparts(fileparts( ...
    mfilename('fullpath')))))).getCanonicalPath());
tool = fullfile(repo, 'tools', 'stage8_core_v2_known_k', 'matlab');
addpath(tool);
source = readtable(fullfile(repo, 'innovation-mining', ...
    '26_stage8_core_v2_known_k_pruning_trials.csv'), ...
    'TextType', 'string');
[rows1, audit1] = stage8_core_v2_build_hybrid_rows(source);
[rows2, audit2] = stage8_core_v2_build_hybrid_rows(source);
assert(isequaln(rows1, rows2));
assert(isequal(audit1, audit2));
assert(height(rows1) == 48 && audit1.element_trial_count == 24);
assert(all(rows1.fit_valid) && audit1.truth_leakage_count == 0);

required_ids = ["R1_K2_N1_L4_EASY"; ...
    "R1_K2_N1_L4_MODERATE"; ...
    "R1_K2_N1_L8_MODERATE"; ...
    "R1_K2_N2_L8_MODERATE"];
fixtures = source(ismember(source.trial_id, required_ids), :);
assert(numel(unique(fixtures.trial_id)) == 4 && height(fixtures) == 12);
easy = fixtures(fixtures.trial_id == "R1_K2_N1_L4_EASY", :);
moderate = fixtures(fixtures.trial_id == "R1_K2_N1_L4_MODERATE", :);
n1_l8 = fixtures(fixtures.trial_id == "R1_K2_N1_L8_MODERATE", :);
n2_l8 = fixtures(fixtures.trial_id == "R1_K2_N2_L8_MODERATE", :);
assert(~candidate_valid_local(easy, "B1_DIRECT_CONTINUOUS_KNOWN_K") && ...
    candidate_valid_local(easy, "B2_GROUPED_CONTINUOUS_KNOWN_K"));
assert(candidate_valid_local(moderate, "B1_DIRECT_CONTINUOUS_KNOWN_K") && ...
    candidate_valid_local(moderate, "B2_GROUPED_CONTINUOUS_KNOWN_K"));
assert(~candidate_valid_local(n1_l8, "B1_DIRECT_CONTINUOUS_KNOWN_K") && ...
    ~candidate_valid_local(n1_l8, "B2_GROUPED_CONTINUOUS_KNOWN_K"));
assert(candidate_valid_local(n2_l8, "B1_DIRECT_CONTINUOUS_KNOWN_K") && ...
    ~candidate_valid_local(n2_l8, "B2_GROUPED_CONTINUOUS_KNOWN_K"));

gate_rows = rows1(ismember(rows1.trial_id, required_ids), :);
assert(all(gate_rows.fit_valid));
assert(all(gate_rows.element_trial_hash == ...
    repelem(unique(fixtures.element_trial_hash, 'stable'), 2)) || ...
    all(ismember(gate_rows.element_trial_hash, fixtures.element_trial_hash)));
assert(any(gate_rows.fallback_flag) && ...
    any(gate_rows.continuous_upgrade_flag));
assert(all(gate_rows.loglik >= gate_rows.B0_candidate_loglik));

b0 = moderate(moderate.method_id == "B0_FIXED_GRID_KNOWN_K", :);
b1 = moderate(moderate.method_id == ...
    "B1_DIRECT_CONTINUOUS_KNOWN_K", :);
[~, source_before] = stage8_core_v2_select_safe_hybrid( ...
    b0, b1, 'H1_DIRECT_SAFE_HYBRID_KNOWN_K');
mutated = b1;
mutated.known_K_joint_RMSE(:) = 1e9;
mutated.support_or_difficulty(:) = "MUTATED";
mutated.noise(:) = "MUTATED";
mutated.L(:) = -1;
mutated.SNR(:) = -999;
[~, source_after] = stage8_core_v2_select_safe_hybrid( ...
    b0, mutated, 'H1_DIRECT_SAFE_HYBRID_KNOWN_K');
assert(source_before == source_after);

tie = b1;
tie.loglik = b0.loglik;
[~, tie_source] = stage8_core_v2_select_safe_hybrid( ...
    b0, tie, 'H1_DIRECT_SAFE_HYBRID_KNOWN_K');
assert(tie_source == "CONTINUOUS_UPGRADE");

invalid_b0 = b0;
invalid_b0.fit_valid = false;
threw = false;
try
    stage8_core_v2_select_safe_hybrid( ...
        invalid_b0, b1, 'H1_DIRECT_SAFE_HYBRID_KNOWN_K');
catch exception
    threw = strcmp(exception.identifier, ...
        'stage8_core_v2_select_safe_hybrid:InvalidFallback');
end
assert(threw);
result = true;
end

function value = candidate_valid_local(rows, method_id)
row = rows(rows.method_id == string(method_id), :);
assert(height(row) == 1);
value = logical(row.fit_valid);
end
