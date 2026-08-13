function checkpoint = stage8_k2_mc_checkpoint_load( ...
    path_now, expected_spec, context, registry_hash)
%STAGE8_K2_MC_CHECKPOINT_LOAD Validate and load one checkpoint.

stage8_k2_mc_checkpoint_validate( ...
    path_now, expected_spec, context, registry_hash);
loaded = load(path_now, 'checkpoint', '-mat');
checkpoint = loaded.checkpoint;
end
