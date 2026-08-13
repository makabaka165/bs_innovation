function path_now = stage8_k2_wcb_checkpoint_path(runtime_root, spec)
%STAGE8_K2_WCB_CHECKPOINT_PATH Resolve one immutable checkpoint path.

path_now = fullfile(runtime_root, 'checkpoints', sprintf( ...
    'trial_%04d_%s.mat', double(spec.global_trial_index), ...
    char(spec.trial_id)));
end
