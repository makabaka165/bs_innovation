function [trials, K1] = build_stage8_1a_validation_trials( ...
    primary_state_value, sensitivity_state_value)
%BUILD_STAGE8_1A_VALIDATION_TRIALS Build all 12,000 synthetic paired rows.

if nargin < 1, primary_state_value = 'K1'; end
if nargin < 2, sensitivity_state_value = 'K1'; end
plan = build_stage8_validation_plan();
trials = materialize_stage8_k1_validation_plan(plan);
state = repmat(string(sensitivity_state_value), height(trials), 1);
primary = trials.measurement_config_id == ...
    string(plan.K1.primary_measurement_config_id);
state(primary) = string(primary_state_value);
trials.state = state;
K1 = plan.K1;
end
