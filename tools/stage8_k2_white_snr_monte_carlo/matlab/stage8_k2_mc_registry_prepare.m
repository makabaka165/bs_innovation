function state = stage8_k2_mc_registry_prepare( ...
    runtime_root, registry, context)
%STAGE8_K2_MC_REGISTRY_PREPARE Create or validate one resumable runtime.

registry_hash = stage8_k2_mc_stable_hash('REGISTRY', registry);
registry_dir = fullfile(runtime_root, 'registry');
state_path = fullfile(runtime_root, 'run_state.mat');
if ~isfolder(runtime_root)
    if isfile(runtime_root) || ~mkdir(runtime_root)
        error('stage8_k2_mc_registry_prepare:RuntimeCreate', ...
            'Unable to create the formal runtime root.');
    end
    directories = {'registry','checkpoints','status','merged','evidence'};
    for index = 1:numel(directories)
        if ~mkdir(fullfile(runtime_root, directories{index}))
            error('stage8_k2_mc_registry_prepare:Directory', ...
                'Unable to create runtime directory: %s', directories{index});
        end
    end
    registry_path = fullfile(registry_dir, 'registry.mat');
    temporary = [registry_path, '.tmp'];
    save(temporary, 'registry', 'registry_hash', '-mat');
    [ok, message] = movefile(temporary, registry_path);
    if ~ok
        error('stage8_k2_mc_registry_prepare:RegistryMove', '%s', message);
    end
    writetable(registry, fullfile(registry_dir, 'registry.csv'));
    stage8_k2_mc_write_text_atomic(fullfile(registry_dir, ...
        'registry_hash.txt'), [registry_hash, newline]);
    stage8_k2_mc_write_text_atomic(fullfile(registry_dir, ...
        'code_identity.txt'), [context.code_identity.tree_hash, newline]);
    run_state = struct('launch_count', 1, 'resume_count', 0, ...
        'created_utc', stage8_k2_mc_utc_now(), ...
        'last_launch_utc', stage8_k2_mc_utc_now());
    mode = "NEW";
else
    required = {registry_dir, fullfile(runtime_root, 'checkpoints'), ...
        fullfile(runtime_root, 'status'), ...
        fullfile(registry_dir, 'registry.mat'), state_path};
    if ~all(cellfun(@(path_now) isfolder(path_now) || isfile(path_now), ...
            required))
        error('stage8_k2_mc_registry_prepare:ResumeSchema', ...
            'Existing runtime is missing a required registry or directory.');
    end
    loaded = load(fullfile(registry_dir, 'registry.mat'), ...
        'registry', 'registry_hash', '-mat');
    if ~strcmp(loaded.registry_hash, registry_hash) || ...
            ~strcmp(stage8_k2_mc_stable_hash('REGISTRY', loaded.registry), ...
            registry_hash)
        error('stage8_k2_mc_registry_prepare:RegistryIdentity', ...
            'Existing runtime registry differs from the current registry.');
    end
    stored_code = strtrim(fileread(fullfile(registry_dir, ...
        'code_identity.txt')));
    if ~strcmp(stored_code, context.code_identity.tree_hash)
        error('stage8_k2_mc_registry_prepare:CodeIdentity', ...
            'Existing runtime was created by a different source tree.');
    end
    loaded_state = load(state_path, 'run_state', '-mat');
    run_state = loaded_state.run_state;
    run_state.launch_count = run_state.launch_count + 1;
    run_state.resume_count = run_state.resume_count + 1;
    run_state.last_launch_utc = stage8_k2_mc_utc_now();
    mode = "RESUME";
end
temporary_state = [state_path, '.tmp'];
if isfile(temporary_state)
    delete(temporary_state);
end
save(temporary_state, 'run_state', '-mat');
[ok, message] = movefile(temporary_state, state_path, 'f');
if ~ok
    error('stage8_k2_mc_registry_prepare:StateMove', '%s', message);
end
state = struct('mode', mode, 'registry_hash', registry_hash, ...
    'run_state', run_state);
end
