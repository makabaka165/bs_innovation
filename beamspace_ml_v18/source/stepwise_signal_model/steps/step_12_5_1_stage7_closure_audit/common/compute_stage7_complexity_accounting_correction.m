function accounting = compute_stage7_complexity_accounting_correction( ...
    result_dir, aliases, dimensions)
%COMPUTE_STAGE7_COMPLEXITY_ACCOUNTING_CORRECTION Separate labels and work.

if nargin < 2 || isempty(aliases)
    aliases = build_stage7_method_subset_alias_table(result_dir);
end
if nargin < 3 || isempty(dimensions)
    dimensions = struct('N_el', 32, 'N_az', 65, ...
        'B_el', 3, 'B_az', 5, 'complex_double_bytes', 16);
end
validate_dimensions_local(dimensions);
summary = read_summary_local(result_dir);
charged_calls = sum(summary.score_calls);
keys = summary.scenario_id + "|" + summary.subset_id;
[~, first_index] = unique(keys, 'stable');
actual_calls = sum(summary.score_calls(first_index));

materialized_bytes = dimensions.complex_double_bytes * ...
    dimensions.N_el * dimensions.N_az * ...
    dimensions.B_el * dimensions.B_az;
elevation_bytes = dimensions.complex_double_bytes * ...
    dimensions.N_el * dimensions.B_el;
azimuth_bytes = dimensions.complex_double_bytes * ...
    dimensions.N_az * dimensions.B_az * dimensions.B_el;
factorized_bytes = elevation_bytes + azimuth_bytes;

accounting = struct();
accounting.actual_unique_subset_score_calls = actual_calls;
accounting.charged_method_score_calls = charged_calls;
accounting.duplicate_method_charge = charged_calls - actual_calls;
accounting.unique_subset_count = numel(unique(aliases.physical_subset_hash));
accounting.method_label_count = height(aliases);
accounting.materialized_equivalent_W_bytes = materialized_bytes;
accounting.factorized_elevation_weight_bytes = elevation_bytes;
accounting.factorized_azimuth_weight_bytes = azimuth_bytes;
accounting.factorized_total_weight_bytes = factorized_bytes;
accounting.materialized_to_factorized_memory_ratio = ...
    materialized_bytes / factorized_bytes;
accounting.original_accounting_semantics = ...
    'CHARGED_METHOD_LABEL_WORK_INCLUDING_PHYSICAL_ALIASES';
accounting.corrected_accounting_semantics = ...
    'ACTUAL_UNIQUE_PHYSICAL_SUBSET_WORK';
accounting.memory_accounting_status = ...
    'MATERIALIZED_EQUIVALENT_W_VERSUS_FACTORIZED_SEQUENTIAL_WEIGHTS';
end

function summary = read_summary_local(result_dir)
if isstring(result_dir), result_dir = char(result_dir); end
if ~(ischar(result_dir) && isrow(result_dir) && exist(result_dir, 'dir') == 7)
    error('compute_stage7_complexity_accounting_correction:ResultDir', ...
        'result_dir must identify the Stage 7 results directory.');
end
names = ["finite_sample_normal_holdout.csv"; ...
    "finite_sample_threshold_holdout.csv"; ...
    "finite_sample_mismatch_holdout.csv"; ...
    "finite_sample_stress_holdout.csv"];
tables = cell(numel(names), 1);
for index = 1:numel(names)
    tables{index} = readtable(fullfile(result_dir, names(index)), ...
        'TextType', 'string');
end
summary = vertcat(tables{:});
end

function validate_dimensions_local(dimensions)
required = {'N_el','N_az','B_el','B_az','complex_double_bytes'};
if ~(isstruct(dimensions) && isscalar(dimensions) && ...
        all(isfield(dimensions, required)))
    error('compute_stage7_complexity_accounting_correction:Dimensions', ...
        'dimensions is missing a required field.');
end
values = cellfun(@(name) dimensions.(name), required);
if any(~isfinite(values) | values <= 0 | values ~= fix(values))
    error('compute_stage7_complexity_accounting_correction:DimensionValue', ...
        'All dimensions and byte counts must be positive integers.');
end
end
