function stage8_k2_rtc_verify(repo,runtime)
c=stage8_k2_rtc_constants();
identity=stage8_k2_rtc_code_identity(repo);
formal=jsondecode(fileread(fullfile(runtime,'controller','formal_identity.json')));
assert(strcmp(identity.head,formal.head) && strcmp(identity.source_hash,formal.source_hash));
loaded=load(fullfile(runtime,'registry','prepared.mat'),'prepared'); prepared=loaded.prepared;
assert(isequaln(stage8_k2_rtc_build_registry(),prepared.registry));
ctx=stage8_k2_rtc_build_context(repo);
assert(isequaln(stage8_k2_rtc_measure_beamwidths(ctx),prepared.beamwidth));
out=fullfile(repo,'innovation-mining');
results=readtable(fullfile(out,'58_stage8_k2_raw_tangent_method_results.csv'),'TextType','string');
plot_data=readtable(fullfile(out,'58_stage8_k2_raw_tangent_plot_data.csv'),'TextType','string');
assert(isequaln(results,plot_data) && height(results)==13440);
assert(height(unique(results(:,{'scenario_id','method_id'})))==13440);
maximum_snr_error=0;
for k=1:1680
    spec=prepared.registry(k,:);
    clean=stage8_k2_rtc_build_clean_signals(spec,ctx.model);
    width=prepared.beamwidth(prepared.beamwidth.profile_id==spec.profile_id,:);
    pair=cell(2,1);
    for d=1:2
        domain="BEAMSPACE";
        if d==2, domain="ELEMENT"; end
        filename=fullfile(runtime,'checkpoints',lower(domain),sprintf('trial_%04d_%s.mat',k,spec.scenario_id));
        cp=stage8_k2_rtc_checkpoint_validate(filename,spec,domain,identity,prepared);
        pair{d}=cp;
        if d==1
            observation=stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed);
        else
            observation=stage8_k2_rtc_generate_element_observation(clean.Xe,spec.nominal_snr_db,spec.element_noise_seed);
        end
        maximum_snr_error=max(maximum_snr_error,abs(observation.nominal_snr_db-spec.nominal_snr_db));
        assert(strcmp(cp.source_hash,clean.source_hash) && strcmp(cp.truth_hash,clean.truth_hash));
        for field=["noise_hash","clean_hash","observation_hash"]
            assert(strcmp(cp.(field),observation.(field)),'RTC:Reconstruction','Observation reconstruction mismatch.');
        end
        for j=1:height(cp.rows)
            row=cp.rows(j,:);
            merged=results(results.scenario_id==spec.scenario_id & results.method_id==row.method_id,:);
            assert(height(merged)==1);
            assert(merged.observation_hash==row.observation_hash && merged.fit_status==row.fit_status && merged.fit_valid==row.fit_valid);
            angles=NaN(2,2);
            if row.fit_valid, angles=jsondecode(row.angles_hat_deg); end
            metrics=stage8_k2_rtc_resolution_metrics(angles,clean.truth,width,row.fit_valid);
            for field=string(fieldnames(metrics)).'
                expected=metrics.(field); actual=merged.(field);
                assert((isnan(expected)&&isnan(actual)) || abs(double(expected)-double(actual))<=1e-10, ...
                    'RTC:MetricAudit','Metric mismatch: %s',field);
            end
            for field=["noise_variance","signal_energy","noise_energy","realized_snr_db"]
                assert(abs(merged.(field)-observation.(field))<=1e-12*max(1,abs(observation.(field))));
            end
        end
    end
    assert(strcmp(pair{1}.source_hash,pair{2}.source_hash) && strcmp(pair{1}.truth_hash,pair{2}.truth_hash));
    assert(pair{1}.noise_seed~=pair{2}.noise_seed && ~strcmp(pair{1}.noise_hash,pair{2}.noise_hash));
end
for k=1:8
    selected=results.method_id==c.method_ids(k);
    assert(nnz(selected)==1680 && nnz(results.applicable(selected))==c.expected_applicable(k));
end
manifest_file=fullfile(out,'58_stage8_k2_raw_tangent_runtime_manifest.json');
manifest=jsondecode(fileread(manifest_file));
for k=1:numel(manifest.artifacts)
    artifact=manifest.artifacts(k);
    assert(strcmp(stage8_k2_rtc_file_sha256(fullfile(repo,artifact.path)),artifact.sha256));
end
script=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','powershell','Stage8K2RTCScope.ps1');
[status,output]=system(sprintf('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%s" -RepoDir "%s" -RequirePruned',script,repo));
assert(status==0,'RTC:Scope','%s',output);
assert(isempty(dir(fullfile(runtime,'**','*.tmp'))) && isempty(dir(fullfile(runtime,'**','*.lock'))));
stage8_k2_rtc_write_json(fullfile(runtime,'status','audit_done.json'), ...
    struct('complete',true,'pass',true,'head',identity.head,'source_hash',identity.source_hash, ...
    'scenario_count',1680,'method_row_count',13440,'nominal_max_error_db',maximum_snr_error));
end
