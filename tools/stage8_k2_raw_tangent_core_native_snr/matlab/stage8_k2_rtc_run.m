function stage8_k2_rtc_run(repo, runtime, domain)
c = stage8_k2_rtc_constants();
assert(ismember(string(domain),["BEAMSPACE","ELEMENT"]));
identity = stage8_k2_rtc_code_identity(repo);
frozen = jsondecode(fileread(fullfile(runtime,'controller','formal_identity.json')));
assert(strcmp(identity.source_hash,frozen.source_hash) && strcmp(identity.head,frozen.head));
loaded = load(fullfile(runtime,'registry','prepared.mat'),'prepared');
prepared = loaded.prepared;
context = stage8_k2_rtc_build_context(repo);
assert(strcmp(context.configuration_hash,prepared.configuration_hash));
resources = stage8_k2_rtc_prepare_resources(context.model,context.domain,domain);
registry = prepared.registry;
for k = 1:height(registry)
    spec = registry(k,:);
    filename = fullfile(runtime,'checkpoints',lower(char(domain)), ...
        sprintf('trial_%04d_%s.mat',k,spec.scenario_id));
    if isfile([filename '.tmp'])
        error('RTC:Temporary','Uncommitted temporary checkpoint: %s',filename);
    end
    if isfile(filename)
        stage8_k2_rtc_checkpoint_validate(filename,spec,domain,identity,prepared);
        continue;
    end
    clean = stage8_k2_rtc_build_clean_signals(spec,context.model);
    width = prepared.beamwidth(prepared.beamwidth.profile_id==spec.profile_id,:);
    if string(domain)=="BEAMSPACE"
        observation = stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed);
        [fits,diagnostics] = stage8_k2_rtc_fit_beamspace_methods(observation.data,context.model, ...
            context.domain,resources,c.core,c.classical);
        ids = c.beamspace_method_ids;
    else
        observation = stage8_k2_rtc_generate_element_observation(clean.Xe,spec.nominal_snr_db,spec.element_noise_seed);
        [fits,diagnostics] = stage8_k2_rtc_fit_element_methods(observation.data,context.model, ...
            context.domain,c.classical,c.structured,true);
        ids = c.element_method_ids;
    end
    rows = cell(numel(fits),1);
    for j = 1:numel(fits)
        rows{j} = stage8_k2_rtc_result_row(spec,ids(j),observation,fits{j},clean.truth,width);
    end
    snr = rmfield(observation,{'data','standard_noise','noise'});
    checkpoint = struct('spec',spec,'domain',char(domain), ...
        'truth_hash',clean.truth_hash,'source_hash',clean.source_hash, ...
        'noise_seed',observation.noise_seed,'noise_hash',observation.noise_hash, ...
        'clean_hash',observation.clean_hash,'observation_hash',observation.observation_hash, ...
        'snr',snr,'rows',struct2table(vertcat(rows{:})),'diagnostics',diagnostics, ...
        'code_identity',identity,'registry_hash',prepared.registry_hash, ...
        'beamwidth_hash',prepared.beamwidth_hash,'configuration_hash',prepared.configuration_hash);
    stage8_k2_rtc_checkpoint_write(filename,checkpoint);
    stage8_k2_rtc_status_write(runtime,string(domain)+"_RUNNING",k,spec.scenario_id);
end
stage8_k2_rtc_write_json(fullfile(runtime,'status',lower(char(domain))+"_done.json"), ...
    struct('complete',true,'count',height(registry),'source_hash',identity.source_hash,'head',identity.head));
end
