function checkpoint = stage8_k2_wacb_checkpoint_load( ...
    path_now, spec, context, registry_hash)
%STAGE8_K2_WACB_CHECKPOINT_LOAD Validate and return one checkpoint.

stage8_k2_wacb_checkpoint_validate(path_now, spec, context, registry_hash);
loaded = load(path_now, 'checkpoint', '-mat');
checkpoint = loaded.checkpoint;
end
