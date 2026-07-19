function digest = stage8_calibration_cell_input_hash( ...
    plan_row, source_identity, calibration_plan_hash)
%STAGE8_CALIBRATION_CELL_INPUT_HASH Hash one cell independent of its shard.

if istable(plan_row) && height(plan_row) == 1
    metadata = table2struct(plan_row);
elseif isstruct(plan_row) && isscalar(plan_row)
    metadata = plan_row;
else
    error('stage8_calibration_cell_input_hash:PlanRow', ...
        'plan_row must be one table row or one scalar struct.');
end
required = {'calibration_cell_id','global_cell_index','model_key', ...
    'fixed_measurement_hash','calibration_data_seed'};
if ~all(isfield(metadata, required))
    error('stage8_calibration_cell_input_hash:PlanRow', ...
        'The frozen calibration plan row is incomplete.');
end
source_identity = string(source_identity);
calibration_plan_hash = string(calibration_plan_hash);
if ~isscalar(source_identity) || strlength(source_identity) == 0 || ...
        ~isscalar(calibration_plan_hash) || strlength(calibration_plan_hash) == 0
    error('stage8_calibration_cell_input_hash:Identity', ...
        'Source and calibration-plan identities must be nonempty scalar text.');
end
digest = stage8_stable_hash('STAGE8_CALIBRATION_CELL_INPUT_V2', ...
    metadata, metadata.calibration_data_seed, metadata.model_key, ...
    metadata.fixed_measurement_hash, source_identity, calibration_plan_hash);
end
