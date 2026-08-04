function checkpoint = stage8_k2_wcb_checkpoint_load( ...
    path_now, expected_spec, context, registry_hash)
%STAGE8_K2_WCB_CHECKPOINT_LOAD Validate and load one checkpoint.

stage8_k2_wcb_checkpoint_validate( ...
    path_now, expected_spec, context, registry_hash);
loaded = load(path_now, 'checkpoint', '-mat');
checkpoint = loaded.checkpoint;
end
