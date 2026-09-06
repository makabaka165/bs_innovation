function stage8_k2_rtc_verify_csv_logical_recovery(repo,runtime)
c=stage8_k2_rtc_constants();
identity=stage8_k2_rtc_code_identity(repo);
formal=jsondecode(fileread(fullfile(runtime,'controller','formal_identity.json')));
assert(strcmp(identity.head,formal.head) && strcmp(identity.source_hash,formal.source_hash));
loaded=load(fullfile(runtime,'registry','prepared.mat'),'prepared'); prepared=loaded.prepared;
assert(isequaln(stage8_k2_rtc_build_registry(),prepared.registry));
ctx=stage8_k2_rtc_build_context(repo);
assert(isequaln(stage8_k2_rtc_measure_beamwidths(ctx),prepared.beamwidth));
out=fullfile(repo,'innovation-mining');
results=readtable(fullfile(out,[c.output_prefix 'method_results.csv']),'TextType','string');
plot_data=readtable(fullfile(out,[c.output_prefix 'plot_data.csv']),'TextType','string');
% CSV has no logical type; restore the frozen result-row schema before indexing.
results=restore_logical_columns(results);
plot_data=restore_logical_columns(plot_data);
assert(isequaln(results,plot_data) && height(results)==c.method_row_count);
assert(height(unique(results(:,{'scenario_id','method_id'})))==c.method_row_count);
assert(all(results.L==8) && all(results.applicable));
assert(isequal(sort(unique(results.profile_id)),sort(c.profile_ids)));
assert(isequal(sort(unique(results.method_id)),sort(c.method_ids)));
assert(isequal(sort(unique(results.nominal_snr_db)),sort(c.snr_db_values.')));
for domain=["beamspace","element"]
    assert(numel(dir(fullfile(runtime,'checkpoints',domain,'*.mat')))==c.scenario_count);
end
registry=readtable(fullfile(out,[c.output_prefix 'registry.csv']),'TextType','string');
compare_tables(prepared.registry,registry);
beamwidth=readtable(fullfile(out,[c.output_prefix 'beamwidth_contract.csv']),'TextType','string');
compare_tables(prepared.beamwidth,beamwidth);
snrs=readtable(fullfile(out,[c.output_prefix 'domain_snr_trials.csv']),'TextType','string');
diagnostics=readtable(fullfile(out,[c.output_prefix 'core_diagnostics.csv']),'TextType','string');
traces=load(fullfile(out,[c.output_prefix 'rho_trace_representatives.mat']),'representatives');
assert(height(snrs)==c.checkpoint_count && height(diagnostics)==c.scenario_count);
assert(numel(traces.representatives)==c.representative_count);
maximum_snr_error=0;
for k=1:c.scenario_count
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
        native=snrs(snrs.scenario_id==spec.scenario_id & snrs.domain==domain,:);
        assert(height(native)==1 && native.observation_hash==string(cp.observation_hash));
        assert(native.source_hash==string(cp.source_hash) && native.truth_hash==string(cp.truth_hash));
        if d==1
            expected=struct2table(stage8_k2_rtc_diagnostic_row(spec,cp.diagnostics,cp.rows(1,:)));
            compare_tables(expected,diagnostics(diagnostics.scenario_id==spec.scenario_id,:));
            if spec.replicate_id==1
                matching=cellfun(@(v) v.spec.scenario_id==spec.scenario_id,traces.representatives);
                assert(nnz(matching)==1);
                saved=traces.representatives{matching};
                assert(isequaln(saved.spec,spec) && isequaln(saved.diagnostics,cp.diagnostics));
            end
        end
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
            compare_tables(row,merged);
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
                assert(abs(native.(field)-observation.(field))<=1e-12*max(1,abs(observation.(field))));
            end
        end
    end
    assert(strcmp(pair{1}.source_hash,pair{2}.source_hash) && strcmp(pair{1}.truth_hash,pair{2}.truth_hash));
    assert(pair{1}.noise_seed~=pair{2}.noise_seed && ~strcmp(pair{1}.noise_hash,pair{2}.noise_hash));
end
for k=1:numel(c.method_ids)
    selected=results.method_id==c.method_ids(k);
    assert(nnz(selected)==c.scenario_count && nnz(results.applicable(selected))==c.expected_applicable(k));
end
pairs=readtable(fullfile(out,[c.output_prefix 'within_domain_pairing.csv']),'TextType','string');
compare_tables(stage8_k2_rtc_pairing(results),pairs);
assert(all(pairs.paired_count==c.replicates));
for metric=["fit_valid","localization_success_01bw","resolution_success"]
    assert(all(pairs.(metric+"_both")+pairs.(metric+"_only_A")+pairs.(metric+"_only_B")+pairs.(metric+"_neither")==c.replicates));
end
assert(all(pairs.rmse_A_wins+pairs.rmse_ties+pairs.rmse_B_wins==pairs.common_valid_count));
for suffix=["snr_summary","scenario_summary","failure_summary","complexity_summary"]
    switch suffix
        case "snr_summary", keys={'domain','method_id','nominal_snr_db'};
        case "scenario_summary", keys={'domain','method_id','profile_id','nominal_snr_db','L'};
        case "failure_summary", keys={'domain','method_id','profile_id','nominal_snr_db','fit_status','elevation_status','conditional_status'};
        case "complexity_summary", keys={'domain','method_id','profile_id'};
    end
    exported=readtable(fullfile(out,[c.output_prefix char(suffix) '.csv']),'TextType','string');
    compare_tables(stage8_k2_rtc_summarize(results,keys),exported);
end
manifest_file=fullfile(out,[c.output_prefix 'runtime_manifest.json']);
manifest=jsondecode(fileread(manifest_file));
assert(strcmp(manifest.protocol,c.protocol));
assert(manifest.registry_count==c.scenario_count && manifest.base_count==c.base_count && ...
    manifest.checkpoint_count==c.checkpoint_count && manifest.method_row_count==c.method_row_count);
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
    'scenario_count',c.scenario_count,'method_row_count',c.method_row_count,'nominal_max_error_db',maximum_snr_error));
end

function compare_tables(expected,actual)
assert(height(expected)==height(actual) && isequal(expected.Properties.VariableNames,actual.Properties.VariableNames));
for field=string(expected.Properties.VariableNames)
    a=expected.(field); b=actual.(field);
    if isnumeric(a) || islogical(a)
        a=double(a); b=double(b);
        allowed=(isnan(a)&isnan(b)) | (a==b) | (abs(a-b)<=1e-10+1e-12*abs(a));
        assert(all(allowed(:)),'RTC:ExportAudit','Export mismatch: %s',field);
    else
        assert(isequal(string(a),string(b)),'RTC:ExportAudit','Export mismatch: %s',field);
    end
end
end

function rows = restore_logical_columns(rows)
fields=["applicable","fit_valid","elevation_valid","conditional_valid", ...
    "rho_lower_bound_hit","localization_success_01bw","resolution_success"];
for field=fields
    assert(ismember(field,string(rows.Properties.VariableNames)), ...
        'RTC:LogicalSchema','Missing logical column: %s',field);
    value=rows.(field);
    assert((isnumeric(value) || islogical(value)) && all(value(:)==0 | value(:)==1), ...
        'RTC:LogicalSchema','Expected exact 0/1 logical column: %s',field);
    rows.(field)=logical(value);
end
end
