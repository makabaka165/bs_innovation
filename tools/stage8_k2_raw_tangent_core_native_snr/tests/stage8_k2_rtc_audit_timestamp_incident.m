function report = stage8_k2_rtc_audit_timestamp_incident(repo,runtime)
cleanup=stage8_k2_rtc_add_paths(repo); %#ok<NASGU>
formal=jsondecode(fileread(fullfile(runtime,'controller','formal_identity.json')));
assert(strcmp(formal.head,'7c4b95a750875c53d554056bc42b01c54b49408e'));
assert(strcmp(formal.source_hash,'ec83baf8e158a8ec705d6d1eee64ba009b77898d45e49e867e3447cfc0d862f0'));
loaded=load(fullfile(runtime,'registry','prepared.mat'),'prepared'); prepared=loaded.prepared;
ctx=stage8_k2_rtc_build_context(repo);
assert(isequaln(stage8_k2_rtc_build_registry(),prepared.registry));
assert(isequaln(stage8_k2_rtc_measure_beamwidths(ctx),prepared.beamwidth));
files=dir(fullfile(runtime,'checkpoints','beamspace','*.mat'));
assert(numel(files)==61 && isempty(dir(fullfile(runtime,'checkpoints','element','*.mat'))));
assert(isempty(dir(fullfile(runtime,'checkpoints','**','*.tmp'))));
artifacts=cell(numel(files),1);
for k=1:numel(files)
    filename=fullfile(files(k).folder,files(k).name);
    before=stage8_k2_rtc_file_sha256(filename);
    spec=prepared.registry(k,:);
    assert(strcmp(files(k).name,sprintf('trial_%04d_%s.mat',k,spec.scenario_id)));
    cp=stage8_k2_rtc_checkpoint_validate(filename,spec,'BEAMSPACE',formal,prepared);
    assert(strcmp(stage8_k2_rtc_hash(cp.code_identity.files),formal.source_hash));
    if k==1
        source_files=cp.code_identity.files;
        for j=1:height(source_files)
            content=strrep(fileread(fullfile(repo,source_files.path(j))),sprintf('\r\n'),sprintf('\n'));
            assert(string(stage8_k2_rtc_hash(content))==source_files.sha256(j));
        end
    else
        assert(isequaln(cp.code_identity.files,source_files));
    end
    clean=stage8_k2_rtc_build_clean_signals(spec,ctx.model);
    o=stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed);
    assert(strcmp(cp.source_hash,clean.source_hash) && strcmp(cp.truth_hash,clean.truth_hash));
    assert(isequaln(cp.snr,rmfield(o,{'data','standard_noise','noise'})));
    width=prepared.beamwidth(prepared.beamwidth.profile_id==spec.profile_id,:);
    for j=1:height(cp.rows)
        row=cp.rows(j,:); angles=NaN(2,2);
        if row.fit_valid, angles=jsondecode(row.angles_hat_deg); end
        metrics=stage8_k2_rtc_resolution_metrics(angles,clean.truth,width,row.fit_valid);
        for field=string(fieldnames(metrics)).'
            assert(isequaln(metrics.(field),row.(field)));
        end
    end
    assert(strcmp(before,stage8_k2_rtc_file_sha256(filename)));
    artifacts{k}=struct('name',files(k).name,'sha256',before,'bytes',files(k).bytes, ...
        'scenario_id',spec.scenario_id,'payload_hash',cp.payload_hash);
end
report=struct('pass',true,'old_identity',formal,'checkpoint_count',numel(files), ...
    'reconstructed_observations',numel(files),'recomputed_metric_rows',3*numel(files), ...
    'checkpoint_bytes_unchanged',true,'source_files',{table2struct(source_files)}, ...
    'checkpoints',{vertcat(artifacts{:})}, ...
    'recovery_policy','ARCHIVE_BYTE_IDENTICAL_THEN_RECOMPUTE_WITH_STRICT_NEW_IDENTITY');
stage8_k2_rtc_write_json(fullfile(runtime,'controller','timestamp_readonly_audit.json'),report);
fprintf('TIMESTAMP INCIDENT AUDIT PASS: 61 checkpoints, 183 metric rows, old source hashes verified.\n');
end
