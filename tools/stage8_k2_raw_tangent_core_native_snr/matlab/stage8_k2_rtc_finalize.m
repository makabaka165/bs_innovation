function stage8_k2_rtc_finalize(repo, runtime)
c=stage8_k2_rtc_constants();
loaded=load(fullfile(runtime,'registry','prepared.mat'),'prepared');
prepared=loaded.prepared;
identity=stage8_k2_rtc_code_identity(repo);
formal=jsondecode(fileread(fullfile(runtime,'controller','formal_identity.json')));
assert(strcmp(identity.head,formal.head) && strcmp(identity.source_hash,formal.source_hash));
n=height(prepared.registry);
assert(n==c.scenario_count);
rows=cell(c.checkpoint_count,1); snrs=cell(c.checkpoint_count,1);
diagnostics=cell(n,1); representatives=cell(c.representative_count,1);
index=0; representative_index=0;
for domain=["BEAMSPACE","ELEMENT"]
    assert(numel(dir(fullfile(runtime,'checkpoints',lower(domain),'*.mat')))==n);
    for k=1:n
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
                representative_index=representative_index+1;
                representatives{representative_index}=struct('spec',spec,'diagnostics',checkpoint.diagnostics);
            end
        end
    end
end
results=vertcat(rows{:});
assert(height(results)==c.method_row_count && representative_index==c.representative_count);
for k=1:numel(c.method_ids)
    selected=results.method_id==c.method_ids(k);
    assert(nnz(selected)==n && nnz(results.applicable(selected))==c.expected_applicable(k));
end
out=fullfile(repo,'innovation-mining');
write_table('domain_snr_trials',struct2table(vertcat(snrs{:})));
write_table('method_results',results);
write_table('plot_data',results);
write_table('core_diagnostics',struct2table(vertcat(diagnostics{:})));
save(fullfile(out,[c.output_prefix 'rho_trace_representatives.mat']),'representatives','-v7');
base={'domain','method_id'};
summary=stage8_k2_rtc_summarize(results,[base {'nominal_snr_db'}]);
assert(all(summary.total==c.base_count));
write_table('snr_summary',summary);
exact=stage8_k2_rtc_summarize(results,[base {'profile_id','nominal_snr_db','L'}]);
assert(all(exact.total==c.replicates));
write_table('scenario_summary',exact);
write_table('failure_summary',stage8_k2_rtc_summarize(results,[base {'profile_id','nominal_snr_db','fit_status','elevation_status','conditional_status'}]));
complexity=stage8_k2_rtc_summarize(results,[base {'profile_id'}]);
write_table('complexity_summary',complexity);
pairs=stage8_k2_rtc_pairing(results);
write_table('within_domain_pairing',pairs);
addpath(fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','plotting'));
plot_manifest=stage8_k2_rtc_plot_from_committed_data(out,fullfile(out,'figures'));
stage8_k2_rtc_write_json(fullfile(out,[c.output_prefix 'plot_manifest.json']),plot_manifest);

report=fullfile(out,[c.output_prefix 'results.md']);
fid=fopen(report,'w','n','UTF-8'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'# Raw Tangent: SC_A / SC_B, L=8\n\nStatus: COMPUTED_PENDING_AUDIT.\n\n');
fprintf(fid,'Source parent: %s. Frozen implementation: %s. Source hash: %s.\n\n',c.base_commit,identity.head,identity.source_hash);
fprintf(fid,'%d scenarios; %d bases; %d native-domain observations/checkpoints; %d method rows; %d replicates per exact condition.\n\n', ...
    n,c.base_count,c.checkpoint_count,c.method_row_count,c.replicates);
fprintf(fid,'Both scenarios: center [8,10] deg, separation 0.45 deg, axis 30 deg. SC_A: secondary power 0 dB, correlation magnitude 0. SC_B: -3 dB and 0.7, with the original source-seeded random correlation phase.\n\n');
fprintf(fid,'These representative scenarios were designed after viewing the parent experiment. They are not a blind holdout. SC_B changes both power and correlation; it cannot isolate either causal effect.\n\n');
fprintf(fid,'Noise variance remains clean signal energy / (linear nominal SNR * sample count), independently in each native domain. Realized SNR fluctuates. The signal stays fixed across SNR; noise alone is scaled. All five methods are structurally applicable; numerical failures count as failures in the full denominator.\n\n');
fprintf(fid,'Localization: d_max_bw <= 0.1. Strict resolution: d_max_bw <= min(0.1,0.4*rho_true_bw). RMSE uses minimum total squared-error label matching; d_max independently uses minimax matching. Quantiles use valid fits only. Every count below has denominator 20: one outcome is 5 percentage points, not a population probability estimate.\n\n');
for profile=c.profile_ids.'
    fprintf(fid,'## %s: Tangent\n\n',profile);
    core=sortrows(exact(exact.profile_id==profile & exact.method_id=="TANGENT_PROFILE_CORE",:),'nominal_snr_db');
    fprintf(fid,'| SNR dB | Valid | Localization | Strict resolution | RMSE median deg | P90 deg |\n|---:|---:|---:|---:|---:|---:|\n');
    for k=1:height(core)
        fprintf(fid,'| %g | %d/%d | %d/%d | %d/%d | %.8g | %.8g |\n',core.nominal_snr_db(k), ...
            core.valid(k),core.total(k),core.localization_success_count(k),core.total(k), ...
            core.resolution_success_count(k),core.total(k),core.median_joint_RMSE_deg(k),core.P90_joint_RMSE_deg(k));
    end
    for metric=["valid","localization_success_count","resolution_success_count"]
        first=core.nominal_snr_db(find(core.(metric)>0,1));
        if isempty(first), first=NaN; end
        fprintf(fid,'\nFirst registered SNR with at least one %s outcome: %g dB. ',metric,first);
    end
    eligible=core.nominal_snr_db(core.valid_rate>=.9 & core.resolution_success_rate>=.8);
    fprintf(fid,'\n\nDescriptive criterion valid>=0.90 and strict resolution>=0.80: SNR points %s. Isolated points do not establish a continuous stable interval. This is neither an experiment validity gate nor an online enabling threshold.\n\n',mat2str(eligible.'));
    fprintf(fid,'### Within-domain references\n\n');
    references=exact(exact.profile_id==profile & exact.method_id~="TANGENT_PROFILE_CORE",:);
    fprintf(fid,'| Method | Native SNR dB | Valid | Localization | Resolution | RMSE median/P90 deg |\n|---|---:|---:|---:|---:|---:|\n');
    for k=1:height(references)
        t=references(k,:);
        fprintf(fid,'| %s | %g | %d/%d | %d/%d | %d/%d | %.8g / %.8g |\n',t.method_id,t.nominal_snr_db, ...
            t.valid,t.total,t.localization_success_count,t.total,t.resolution_success_count,t.total, ...
            t.median_joint_RMSE_deg,t.P90_joint_RMSE_deg);
    end
    comparisons=pairs(pairs.profile_id==profile & pairs.method_A=="TANGENT_PROFILE_CORE",:);
    fprintf(fid,'\nPositive resolution count difference favors Tangent; negative favors the reference. RMSE wins/ties/losses use only jointly valid estimates, tolerance 1e-6 deg.\n\n');
    fprintf(fid,'| Reference on same Z | SNR dB | Resolution count difference | Common valid | Tangent RMSE wins/ties/losses |\n|---|---:|---:|---:|---:|\n');
    for k=1:height(comparisons)
        t=comparisons(k,:);
        fprintf(fid,'| %s | %g | %+d | %d | %d/%d/%d |\n',t.method_B,t.nominal_snr_db, ...
            t.resolution_success_only_A-t.resolution_success_only_B,t.common_valid_count,t.rmse_A_wins,t.rmse_ties,t.rmse_B_wins);
    end
end
fprintf(fid,'\n## Computation and interpretation\n\n| Scenario | Method | Trials | Score calls | SVD calls | Eig calls | Runtime median/P90 sec |\n|---|---|---:|---:|---:|---:|---:|\n');
for k=1:height(complexity)
    t=complexity(k,:);
    fprintf(fid,'| %s | %s | %d | %d | %d | %d | %.6g / %.6g |\n',t.profile_id,t.method_id,t.total, ...
        t.score_call_count,t.SVD_call_count,t.eig_call_count,t.runtime_median_sec,t.runtime_P90_sec);
end
fprintf(fid,'\nRuntime is descriptive wall time on this workstation, with MATLAB R2022b -singleCompThread and one verified compute worker. Scheduled interruptions, host load and dictionary preparation can affect timing. Score/SVD/eig counts do not by themselves prove an end-to-end speedup. No timing reruns or tuning are performed.\n\n');
fprintf(fid,'Three Beamspace methods share Z; two Element methods share Y_e. Cross-domain results are scenario-matched references at equal nominal SNR in different native domains and use different observations. They support no cross-domain paired wins/losses or same-physical-observation claim.\n\n');
fprintf(fid,'Results apply to these two local off-grid, known-K=2, single-CPI conditions, this fixed aperture and the registered SNR grid. They do not establish general superiority, robustness outside these conditions, or production readiness. Poor performance is a scientific outcome, not experimental invalidity.\n\n');
fprintf(fid,'The adjacent scenario, failure, complexity and pairing CSVs retain valid counts, d_max, axis/rho error, lower-bound hits, Root elevation/conditional failure stages and all within-domain cross-counts. Equal-weight pooled SNR statistics are supplementary. The eight figures regenerate from committed plot_data.csv and representative trace MAT only, without runtime or fitting.\n\n');
fprintf(fid,'Scientific core and budgets, native SNR formula and success criteria are unchanged. No Tangent cache, fixed-K2 fallback or Toeplitz path is introduced. Earlier evidence is available at the source parent and is never merged with these observations. NEXT=USER_REVIEW; MERGE_BACK=NOT_AUTHORIZED.\n');
clear cleanup
files=[dir(fullfile(out,[c.output_prefix '*']));dir(fullfile(out,'figures','60_*.png'))];
artifacts=cell(0,1);
for k=1:numel(files)
    if files(k).isdir || contains(files(k).name,'runtime_manifest'), continue; end
    filename=fullfile(files(k).folder,files(k).name);
    relative=strrep(filename(numel(repo)+2:end),'\','/');
    artifacts{end+1,1}=struct('path',relative,'bytes',files(k).bytes,'sha256',stage8_k2_rtc_file_sha256(filename)); %#ok<AGROW>
end
manifest=struct('protocol',c.protocol,'status','COMPUTED_PENDING_AUDIT', ...
    'code_identity',rmfield(identity,'files'),'source_parent',c.base_commit, ...
    'registry_count',n,'base_count',c.base_count,'native_observation_count',c.checkpoint_count, ...
    'checkpoint_count',c.checkpoint_count,'method_row_count',height(results), ...
    'representative_count',numel(representatives),'beamwidth_hash',prepared.beamwidth_hash, ...
    'artifacts',{vertcat(artifacts{:})},'next','INDEPENDENT_AUDIT','merge_back','NOT_AUTHORIZED');
stage8_k2_rtc_write_json(fullfile(out,[c.output_prefix 'runtime_manifest.json']),manifest);
stage8_k2_rtc_write_json(fullfile(runtime,'status','finalize_done.json'),struct('complete',true,'head',identity.head,'source_hash',identity.source_hash));
    function write_table(suffix,t)
        writetable(t,fullfile(out,[c.output_prefix suffix '.csv']));
    end
end
