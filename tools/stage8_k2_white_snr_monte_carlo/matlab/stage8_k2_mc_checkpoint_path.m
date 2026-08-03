function path_now = stage8_k2_mc_checkpoint_path(runtime_root, spec)
%STAGE8_K2_MC_CHECKPOINT_PATH Resolve one immutable checkpoint path.

path_now = fullfile(runtime_root, 'checkpoints', sprintf( ...
    'trial_%04d_%s.mat', spec.global_trial_index, char(spec.trial_id)));
end
