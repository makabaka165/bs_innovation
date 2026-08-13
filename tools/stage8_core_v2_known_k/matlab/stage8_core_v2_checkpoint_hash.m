function digest = stage8_core_v2_checkpoint_hash(checkpoint)
%STAGE8_CORE_V2_CHECKPOINT_HASH Hash runtime-independent trial content.

rows = sortrows(checkpoint.rows, 'method_id');
if ismember('runtime_sec', rows.Properties.VariableNames)
    rows.runtime_sec(:) = 0;
end
digest = stage8_stable_hash( ...
    'STAGE8_CORE_V2_ELEMENT_TRIAL_CHECKPOINT_V2', ...
    checkpoint.identity, rows, ...
    char(string(checkpoint.completion_status)));
end
