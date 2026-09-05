function stage8_k2_rtc_finalize(repo, runtime)
c=stage8_k2_rtc_constants();
loaded=load(fullfile(runtime,'registry','prepared.mat'),'prepared');
prepared=loaded.prepared;
identity=stage8_k2_rtc_code_identity(repo);
rows=cell(3360,1); snrs=cell(3360,1); diagnostics=cell(1680,1); representatives=cell(0,1);
index=0;
for domain=["BEAMSPACE","ELEMENT"]
    for k=1:1680
        spec=prepared.registry(k,:);
        filename=fullfile(runtime,'checkpoints',lower(domain),sprintf('trial_%04d_%s.mat',k,spec.scenario_id));
        checkpoint=stage8_k2_rtc_checkpoint_validate(filename,spec,domain,identity,prepared);
        index=index+1;
        rows{index}=checkpoint.rows;
        snr=checkpoint.snr;
        snr.scenario_id=spec.scenario_id;
        snr.base_realization_index=spec.base_realization_index;
        snr.profile_id=spec.profile_id; snr.L=spec.L; snr.replicate_id=spec.replicate_id;
        snr.source_hash=checkpoint.source_hash; snr.truth_hash=checkpoint.truth_hash;
        snrs{index}=snr;
        if domain=="BEAMSPACE"
            diagnostics{k}=stage8_k2_rtc_diagnostic_row(spec,checkpoint.diagnostics,checkpoint.rows(1,:));
            if spec.replicate_id==1
                representatives{end+1,1}=struct('spec',spec,'diagnostics',checkpoint.diagnostics); %#ok<AGROW>
            end
        end
    end
end
results=vertcat(rows{:});
assert(height(results)==13440);
for k=1:8
    selected=results.method_id==c.method_ids(k);
    assert(nnz(selected)==1680 && nnz(results.applicable(selected))==c.expected_applicable(k));
end
out=fullfile(repo,'innovation-mining');
write_table('domain_snr_trials',struct2table(vertcat(snrs{:})));
write_table('method_results',results);
write_table('plot_data',results);
write_table('core_diagnostics',struct2table(vertcat(diagnostics{:})));
save(fullfile(out,'58_stage8_k2_raw_tangent_rho_trace_representatives.mat'),'representatives','-v7');
base={'domain','method_id'};
summary=stage8_k2_rtc_summarize(results,[base {'nominal_snr_db'}]);
write_table('snr_summary',summary);
write_table('profile_summary',stage8_k2_rtc_summarize(results,[base {'nominal_snr_db','profile_id'}]));
write_table('snapshot_summary',stage8_k2_rtc_summarize(results,[base {'nominal_snr_db','L'}]));
exact=stage8_k2_rtc_summarize(results,[base {'nominal_snr_db','profile_id','L'}]);
assert(all(exact.total==20));
write_table('exact_cell_summary',exact);
write_table('success_summary',summary);
write_table('failure_summary',stage8_k2_rtc_summarize(results,[base {'nominal_snr_db','applicable','fit_status'}]));
write_table('native_domain_comparison',summary);
write_table('complexity_summary',stage8_k2_rtc_summarize(results,base));
plot_dir=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','plotting');
addpath(plot_dir);
plot_manifest=stage8_k2_rtc_plot_from_committed_data(out,fullfile(out,'figures'));
stage8_k2_rtc_write_json(fullfile(out,'58_stage8_k2_raw_tangent_plot_manifest.json'),plot_manifest);
core=summary(summary.method_id=="TANGENT_PROFILE_CORE",:);
eligible=core.nominal_snr_db(core.valid_rate>=.9 & core.resolution_success_rate>=.8);
region='RAW_TANGENT_NO_HIGH_RELIABILITY_REGION_IDENTIFIED';
first=NaN;
if ~isempty(eligible), region='RAW_TANGENT_HIGH_RELIABILITY_REGION_IDENTIFIED'; first=min(eligible); end
report=fullfile(out,'58_stage8_k2_raw_tangent_core_native_snr_results.md');
fid=fopen(report,'w','n','UTF-8'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'# Raw Tangent Core Native-SNR Results\n\nStatus: COMPUTED. Final completion and independent audit status are recorded in the runtime manifest.\n\n');
fprintf(fid,'Source main: `%s`. Experiment code: `%s`.\n\n',c.base_commit,identity.head);
fprintf(fid,'1680 scenarios; 240 base realizations; 20 replicates per exact cell; 3360 independent native-domain observations; 13440 method rows.\n\n');
fprintf(fid,'Noise variance in each domain is clean signal energy / (linear nominal SNR * sample count). Realized SNR fluctuates naturally. Noise is IID circular complex Gaussian only.\n\n');
fprintf(fid,'K1_WHITE_SINGLE_TARGET_DML_CENTER is the self-contained whitened-domain single-target center estimator. It does not reproduce the historical element-dependent grouped initialization. All profile scores use the full two-target manifold with requested rank 2. Invalid Core outputs remain invalid.\n\n');
fprintf(fid,'Within each native domain all methods share the same observation hash. Cross-domain curves are SCENARIO_MATCHED_NATIVE_DOMAIN_SNR_REFERENCE; there are no cross-domain trial wins/losses or same-observation claims.\n\n');
fprintf(fid,'Localization: d_max_bw <= 0.1. Resolution: d_max_bw <= min(0.1, 0.4*rho_true_bw). Denominators are applicable trials; structural N/A and algorithmic invalid are separate. Error quantiles use valid fits only. Exact-cell tails are descriptive at N=20.\n\n');
fprintf(fid,'| Nominal SNR dB | Valid rate | Localization | Resolution | Median RMSE deg | P90 RMSE deg |\n|---:|---:|---:|---:|---:|---:|\n');
for k=1:height(core)
    fprintf(fid,'| %g | %.6f | %.6f | %.6f | %.8g | %.8g |\n',core.nominal_snr_db(k),core.valid_rate(k), ...
        core.localization_success_rate(k),core.resolution_success_rate(k),core.median_joint_RMSE_deg(k),core.P90_joint_RMSE_deg(k));
end
fprintf(fid,'\nDescriptive region: `%s`; first SNR: %g dB. This is not an online threshold.\n\n',region,first);
fprintf(fid,'Profile/L, axis/rho, failure composition, within-domain methods, SNR realizations and runtime are retained in the adjacent 58 CSV tables. All figures regenerate from plot_data.csv and rho_trace_representatives.mat without fitting.\n\n');
fprintf(fid,'Historical 43-48 Safe evidence remains byte-identical and is not merged into these results. Deleted 72-trial and cache routes remain at main@644fc6e and in the verified local bundle. Production integration is not authorized.\n');
clear cleanup
files=[dir(fullfile(out,'58_stage8_k2_raw_tangent_*'));dir(fullfile(out,'figures','58_*.png'))];
artifacts=cell(0,1);
for k=1:numel(files)
    if files(k).isdir || contains(files(k).name,'runtime_manifest'), continue; end
    filename=fullfile(files(k).folder,files(k).name);
    relative=strrep(filename(numel(repo)+2:end),'\','/');
    artifacts{end+1,1}=struct('path',relative,'bytes',files(k).bytes,'sha256',stage8_k2_rtc_file_sha256(filename)); %#ok<AGROW>
end
manifest=struct('protocol',c.protocol,'status','COMPUTED_PENDING_INDEPENDENT_AUDIT', ...
    'code_identity',rmfield(identity,'files'),'registry_count',1680,'base_count',240, ...
    'native_observation_count',3360,'method_row_count',13440,'beamwidth_hash',prepared.beamwidth_hash, ...
    'artifacts',{vertcat(artifacts{:})},'region_status',region,'first_descriptive_snr_db',first);
stage8_k2_rtc_write_json(fullfile(out,'58_stage8_k2_raw_tangent_runtime_manifest.json'),manifest);
stage8_k2_rtc_write_json(fullfile(runtime,'status','finalize_done.json'),struct('complete',true,'head',identity.head,'source_hash',identity.source_hash));
    function write_table(suffix,t)
        writetable(t,fullfile(out,['58_stage8_k2_raw_tangent_' suffix '.csv']));
    end
end
