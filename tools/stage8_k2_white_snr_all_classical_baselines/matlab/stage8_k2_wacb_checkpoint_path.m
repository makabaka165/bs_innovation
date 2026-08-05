function path_now = stage8_k2_wacb_checkpoint_path(runtime_root, spec)
%STAGE8_K2_WACB_CHECKPOINT_PATH Return the registered trial checkpoint path.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_k2_wacb_checkpoint_path:Spec', ...
        'spec must be one registry row.');
end
name = sprintf('trial_%04d_%s.mat', double(spec.global_trial_index), ...
    char(spec.trial_id));
path_now = fullfile(runtime_root, 'checkpoints', name);
end
