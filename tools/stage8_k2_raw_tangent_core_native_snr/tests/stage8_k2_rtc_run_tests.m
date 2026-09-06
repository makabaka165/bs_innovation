function report=stage8_k2_rtc_run_tests(repo,runtime)
cleanup=stage8_k2_rtc_add_paths(repo); %#ok<NASGU>
c=stage8_k2_rtc_constants();
prepared=stage8_k2_rtc_prepare(repo,runtime);
ctx=stage8_k2_rtc_build_context(repo);
registry=prepared.registry; widths=prepared.beamwidth;
tests=cell(18,1);
timer=tic;
assert(c.scenario_count==280 && c.base_count==40 && c.checkpoint_count==560 && c.method_row_count==1400);
assert(isequal(c.profile_ids,["SC_A";"SC_B"]) && isequal(c.profile_values,[8 10 .45 30 0 0;8 10 .45 30 -3 .7]));
assert(all(registry.L==8) && isequal(c.snr_db_values,[-6 0 6 10 14 18 22]) && c.replicates==20);
assert(isequal(c.method_ids,["TANGENT_PROFILE_CORE";"FULL4D_BEAMSPACE_CML_MULTISTART"; ...
    "BEAMSPACE_MUSIC_K2";"FULL4D_ELEMENT_CML_MULTISTART";"ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML"]));
assert(all(registry.base_realization_index==(double(registry.profile_id=="SC_B"))*20+registry.replicate_id));
for p=1:numel(c.profile_ids)
    truth=stage8_k2_rtc_build_truth(registry(find(registry.profile_id==c.profile_ids(p),1),:));
    assert(all(truth(:,1)>=7.4 & truth(:,1)<=8.6 & truth(:,2)>=9.8 & truth(:,2)<=10.2));
end
paths=stage8_k2_rtc_source_paths(repo); static_issues=cell(numel(paths),1);
for k=1:numel(paths)
    if ~endsWith(paths{k},'.m'), continue; end
    filename=fullfile(repo,paths{k});
    issues=checkcode(filename,'-struct');
    static_issues{k}=struct('path',paths{k},'issues',issues);
    assert(~any(contains(string({issues.message}),["Parse error","Unable to parse"])));
    [~,name]=fileparts(filename);
    if ~contains(paths{k},'/tests/') && ~contains(paths{k},'/plotting/')
        resolved=which(name,'-all');
        if ischar(resolved), resolved={resolved}; end
        assert(~isempty(resolved) && all(startsWith(string(resolved),string(repo),'IgnoreCase',true)), ...
            'RTC:PathIsolation','Function outside this worktree: %s',name);
    end
end
stage8_k2_rtc_write_json(fullfile(runtime,'tests','static_analysis.json'),static_issues);
addpath(fullfile(repo,'tools','stage8_k2_classical_baselines','tests'));
test_music_two_peak_fixture();
script=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','powershell','Stage8K2RTCScope.ps1');
[status,output]=system(sprintf('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%s" -RepoDir "%s"',script,repo));
assert(status==0,'RTC:T1','%s',output);
[status,branch]=system('git branch --show-current'); assert(status==0 && strcmp(strtrim(branch),c.branch));
record(1,'Git/worktree identity');

% The fluctuation check needs the registered base ensemble, not two samples.
fixtures=registry;
maximum=zeros(1,2); realized=cell(1,2); first=cell(c.base_count,2);
for k=1:height(fixtures)
    spec=fixtures(k,:); clean=stage8_k2_rtc_build_clean_signals(spec,ctx.model);
    observations={stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed), ...
        stage8_k2_rtc_generate_element_observation(clean.Xe,spec.nominal_snr_db,spec.element_noise_seed)};
    assert(observations{1}.noise_seed~=observations{2}.noise_seed && ...
        ~strcmp(observations{1}.noise_hash,observations{2}.noise_hash));
    for d=1:2
        o=observations{d}; X=clean.Xw; if d==2, X=clean.Xe; end
        variance=norm(X,'fro')^2/(numel(X)*10^(spec.nominal_snr_db/10));
        assert(o.noise_variance==variance || abs(o.noise_variance-variance)<=4*eps(variance));
        assert(norm(o.noise-sqrt(variance)*o.standard_noise,'fro')<=1e-12*norm(o.noise,'fro'));
        maximum(d)=max(maximum(d),abs(o.nominal_snr_db-spec.nominal_snr_db));
        realized{d}(end+1)=o.realized_snr_db-spec.nominal_snr_db;
        base=spec.base_realization_index;
        if isempty(first{base,d})
            first{base,d}={o.noise_hash,clean.source_hash};
        else
            assert(strcmp(first{base,d}{1},o.noise_hash) && strcmp(first{base,d}{2},clean.source_hash));
        end
    end
end
realized_spread=cellfun(@std,realized);
fprintf('SNR max errors: %g / %g dB; realized spread: %g / %g dB\n',maximum,realized_spread);
assert(all(maximum<=1e-12) && all(realized_spread>.01));
record(2,'Beamspace nominal variance and common random numbers');
record(3,'Element nominal variance and independent seeds');

scale_fixtures=registry(registry.replicate_id==1 & registry.nominal_snr_db==22 & registry.L==8,:);
assert(height(scale_fixtures)==numel(c.profile_ids));
scale_errors=zeros(height(scale_fixtures),4); scale_valid=0;
for k=1:height(scale_fixtures)
    spec=scale_fixtures(k,:); clean=stage8_k2_rtc_build_clean_signals(spec,ctx.model);
    o=stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed);
    alpha=1/sqrt(o.noise_variance);
    old=alpha*clean.Xw+o.standard_noise;
    assert(norm(old-alpha*o.data,'fro')/norm(old,'fro')<=1e-12);
    [a,da]=stage8_k2_rtc_fit_core(old,ctx.model,ctx.domain,c.core);
    [b,db]=stage8_k2_rtc_fit_core(o.data,ctx.model,ctx.domain,c.core);
    assert(a.fit_valid==b.fit_valid && strcmp(a.fit_status,b.fit_status));
    scale_errors(k,1)=max(abs(da.k1.angles_hat_deg-db.k1.angles_hat_deg));
    assert(scale_errors(k,1)<=c.core.fminbnd_TolX_deg,'RTC:T4','K1 scale equivalence failed.');
    if da.direction.valid && db.direction.valid
        ua=da.direction.direction_hat; ub=db.direction.direction_hat;
        scale_errors(k,2)=min(norm(ua-ub),norm(ua+ub));
        assert(scale_errors(k,2)<=1e-6,'RTC:T4','Direction scale equivalence failed.');
    end
    if a.fit_valid
        scale_valid=scale_valid+1;
        scale_errors(k,3)=abs(da.scale.rho_hat_deg-db.scale.rho_hat_deg);
        scale_errors(k,4)=min(norm(a.angles_hat_deg-b.angles_hat_deg,'fro'),norm(a.angles_hat_deg-b.angles_hat_deg([2 1],:),'fro'));
        % The center's frozen outer stopping tolerance is 1e-3 degrees.
        assert(all(scale_errors(k,3:4)<=1e-3),'RTC:T4','Scale/angle equivalence failed.');
    end
end
assert(scale_valid>0);
record(4,'Two scale-equivalence fixtures');

active=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','matlab');
files=dir(fullfile(active,'*.m'));
for k=1:numel(files)
    text=fileread(fullfile(files(k).folder,files(k).name));
    assert(isempty(regexp(text,'\btoeplitz\s*\(|STAGE5_TOEPLITZ_CORRELATED|build_stage8_locked_plan\s*\(','once')));
end
record(5,'No correlated-noise active construction');
assert(isequaln(stage8_k2_rtc_measure_beamwidths(ctx),widths));
assert(all(widths.az_bw_3db_deg>0 & widths.el_bw_3db_deg>0));
record(6,'Repeatable mechanical beamwidths and crossings');
for p=1:numel(c.profile_ids)
    spec=registry(find(registry.profile_id==c.profile_ids(p),1),:); truth=stage8_k2_rtc_build_truth(spec);
    width=widths(p,:); estimate=truth+[.02 -.03; -.01 .015];
    original=stage8_k2_rtc_resolution_metrics(estimate,truth,width,true);
    swapped_estimate=stage8_k2_rtc_resolution_metrics(estimate([2 1],:),truth,width,true);
    swapped_truth=stage8_k2_rtc_resolution_metrics(estimate,truth([2 1],:),width,true);
    for field=["d_max_bw","d_max_deg","localization_success_01bw","resolution_success"]
        assert(isequal(original.(field),swapped_estimate.(field)) && isequal(original.(field),swapped_truth.(field)));
    end
    collapsed=stage8_k2_rtc_resolution_metrics(repmat(mean(truth,1),2,1),truth,width,true);
    assert(~collapsed.resolution_success);
    exact=stage8_k2_rtc_resolution_metrics(truth,truth,width,true);
    assert(exact.d_max_bw==0 && exact.localization_success_01bw && exact.resolution_success);
end
record(7,'Endpoint permutation invariance'); record(8,'SC_A/SC_B center collapse rejection'); record(9,'Truth endpoint success');

spec=registry(find(registry.profile_id=="SC_A" & registry.L==8 & registry.nominal_snr_db==22,1),:);
clean=stage8_k2_rtc_build_clean_signals(spec,ctx.model);
o=stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed);
k1=stage8_k2_rtc_fit_k1_white(o.data,ctx.model,ctx.domain,c.core);
assert(k1.fit_valid && k1.coarse_count==21 && k1.loglik_concentrated>=k1.coarse_loglik);
assert(all(k1.history.score_after>=k1.history.score_before));
assert(k1.angles_hat_deg(1)>=7.4 && k1.angles_hat_deg(1)<=8.6 && k1.angles_hat_deg(2)>=9.8 && k1.angles_hat_deg(2)<=10.2);
record(10,'21-point K1 and monotone continuous refinement');

profile clear; profile on;
[fit,diagnostic]=stage8_k2_rtc_fit_core(o.data,ctx.model,ctx.domain,c.core);
profile off; profiler=profile('info');
names=string({profiler.FunctionTable.FunctionName});
assert(~any(contains(names,'estimate_stage8_known_k_local_cell')));
assert(~any(contains(string(fieldnames(fit)),["fallback","upgrade"])));
record(11,'Runtime public fixed-K2 call count zero');
for forbidden=["stage8_k2_tcc_","stage8_k2_tfbc_","fixed_registered_manifold_provider", ...
        "fixed_registered_center_adapter","t4_manifold_provider","manifold_provider", ...
        "FIXED_GRID_FALLBACK","FINAL_SAFE_SELECTOR"]
    assert(~any(contains(names,forbidden)));
    for file=["fit_core","fit_k1_white","projected_direction","profile_scale_direct"]
        assert(~contains(fileread(fullfile(active,"stage8_k2_rtc_"+file+".m")),forbidden));
    end
end
assert(any(contains(names,'build_full_sequential_local_manifold')));
record(12,'Direct-only Core reachable route');
scale=stage8_k2_rtc_profile_scale_direct(o.data,ctx.model,[8 10],[1 1],ctx.domain,c.core);
assert(scale.valid && numel(scale.scan_nodes_deg)==33);
for item=scale.trace.'
    if ~item.valid, continue; end
    assert(item.requested_rank==2);
    G=build_full_sequential_local_manifold(item.angles_deg,ctx.model,struct('rank_multiplier',1));
    [score,rss,~,ll,rank]=concentrated_dml_rss(o.data,G,struct('requested_rank',2,'compute_projector_checks',false));
    assert(rank==2 && abs(score-item.score)<=1e-10 && abs(rss-item.rss)<=1e-10 && abs(ll-item.loglik)<=1e-8);
end
record(13,'Every valid scale node scores the full K2 manifold');

beam_resources=stage8_k2_rtc_prepare_resources(ctx.model,ctx.domain,'BEAMSPACE');
assert(isempty(fieldnames(stage8_k2_rtc_prepare_resources(ctx.model,ctx.domain,'ELEMENT'))));
smoke=registry(registry.replicate_id==1 & ismember(registry.nominal_snr_db,[-6 22]),:);
assert(height(smoke)==4);
fixture_dir=fullfile(runtime,'tests','smoke');
if ~isfolder(fixture_dir), mkdir(fixture_dir); end
smoke_rows=cell(height(smoke),1); representatives=cell(height(smoke),1);
identity=stage8_k2_rtc_code_identity(repo);
for trial=1:height(smoke)
    spec=smoke(trial,:); clean=stage8_k2_rtc_build_clean_signals(spec,ctx.model);
    o=stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed);
    oe=stage8_k2_rtc_generate_element_observation(clean.Xe,spec.nominal_snr_db,spec.element_noise_seed);
    [beamfits,beamdiag]=stage8_k2_rtc_fit_beamspace_methods(o.data,ctx.model,ctx.domain,beam_resources,c.core,c.classical);
    [elementfits,elementdiag]=stage8_k2_rtc_fit_element_methods(oe.data,ctx.model,ctx.domain,c.classical,c.structured,true);
    assert(numel(beamfits)==3 && numel(elementfits)==2);
    method_rows=cell(numel(c.method_ids),1);
    width=widths(widths.profile_id==spec.profile_id,:);
    for k=1:numel(beamfits)
        method_rows{k}=stage8_k2_rtc_result_row(spec,c.beamspace_method_ids(k),o,beamfits{k},clean.truth,width);
    end
    for k=1:numel(elementfits)
        method_rows{k+numel(beamfits)}=stage8_k2_rtc_result_row(spec,c.element_method_ids(k),oe,elementfits{k},clean.truth,width);
    end
    fixture=struct2table(vertcat(method_rows{:}));
    assert(all(fixture.applicable) && height(fixture)==5);
    assert(all(fixture.observation_hash(1:3)==string(o.observation_hash)));
    assert(all(fixture.observation_hash(4:5)==string(oe.observation_hash)));
    smoke_rows{trial}=fixture;
    representatives{trial}=struct('spec',spec,'diagnostics',beamdiag);
    for d=1:2
        observation=o; diag=beamdiag; selection=1:3;
        if d==2, observation=oe; diag=elementdiag; selection=4:5; end
        cp=struct('spec',spec,'domain',observation.domain,'source_hash',clean.source_hash,'truth_hash',clean.truth_hash, ...
            'noise_seed',observation.noise_seed,'noise_hash',observation.noise_hash, ...
            'clean_hash',observation.clean_hash,'observation_hash',observation.observation_hash, ...
            'snr',rmfield(observation,{'data','standard_noise','noise'}),'rows',fixture(selection,:),'diagnostics',diag, ...
            'code_identity',identity,'registry_hash',prepared.registry_hash,'beamwidth_hash',prepared.beamwidth_hash, ...
            'configuration_hash',prepared.configuration_hash);
        filename=fullfile(fixture_dir,sprintf('%s_%s.mat',spec.scenario_id,observation.domain));
        stage8_k2_rtc_checkpoint_write(filename,cp);
        stage8_k2_rtc_checkpoint_validate(filename,spec,observation.domain,identity,prepared);
    end
    fprintf('SMOKE %s: %d/5 numerically valid; all five applicable\n',spec.scenario_id,nnz(fixture.fit_valid));
    if spec.profile_id=="SC_A" && spec.nominal_snr_db==22
        direct=stage8_k2_cb_full4d_cml(o.data,ctx.model,ctx.domain,'BEAMSPACE',struct(),c.classical);
        equivalent(beamfits{2},direct);
        assert(direct.coarse_candidate_count==210 && direct.continuous_start_count==6);
        compat=c.classical; compat.snr_db_values=0; compat.profile_ids=0;
        direct=stage8_k2_cb_music(o.data,beam_resources.entry,beam_resources,'BEAMSPACE',8,compat);
        equivalent(beamfits{3},direct);
        whitening=struct('whitener',speye(2080),'method','NATIVE_IID_IDENTITY','whitening_error',0);
        direct=stage8_k2_cb_full4d_cml(oe.data,ctx.model,ctx.domain,'ELEMENT',whitening,c.classical);
        equivalent(elementfits{1},direct);
        R=stage8_k2_sb_vertical_covariance(oe.data,struct('W_az',eye(65),'az_whitening_error',0),c.structured);
        Rfb=stage8_k2_sb_fbss_covariance(R,eye(32),c.structured);
        elevation=stage8_k2_sb_root_music(Rfb,ctx.model,c.structured);
        assert(isequaln(elevation.elevations_hat_deg,elementdiag.elevation.elevations_hat_deg));
        if elevation.fit_valid
            direct=stage8_k2_sb_conditional_az_cml(oe.data,elevation.elevations_hat_deg,ctx.model,whitening,c.structured);
            equivalent(elementfits{2},direct);
        else
            assert(~elementfits{2}.fit_valid);
        end
    end
end
clear beam_resources
fixture=vertcat(smoke_rows{:});
writetable(fixture,fullfile(fixture_dir,[c.output_prefix 'plot_data.csv']));
save(fullfile(fixture_dir,[c.output_prefix 'rho_trace_representatives.mat']),'representatives','-v7');
pairing=stage8_k2_rtc_pairing(fixture);
assert(height(pairing)==numel(c.profile_ids)*numel(c.snr_db_values)*4);
present=pairing.paired_count>0;
assert(all(pairing.paired_count(present)==1));
for metric=["fit_valid","localization_success_01bw","resolution_success"]
    assert(all(pairing.(metric+"_both")+pairing.(metric+"_only_A")+pairing.(metric+"_only_B")+pairing.(metric+"_neither")==pairing.paired_count));
end
writetable(pairing,fullfile(fixture_dir,'within_domain_pairing.csv'));
record(14,'Four five-method smoke cases and retained wrappers match direct kernels');
assert(~isfield(ctx.model.array_configuration,'tgt'));
for constants={c.core,c.classical,c.structured}
    assert(~any(contains(lower(string(fieldnames(constants{1}))),["truth","profile","snr","beamwidth","success"])));
end
for file=["fit_core","fit_k1_white","projected_direction","profile_scale_direct","fit_beamspace_methods","fit_element_methods"]
    source=fileread(fullfile(active,"stage8_k2_rtc_"+file+".m"));
    assert(isempty(regexp(source,'\b(truth|profile_id|nominal_snr_db|realized_snr_db|beamwidth|tau_trial_bw)\b','once')));
end
record(15,'Scenario truth, SNR and thresholds isolated from fitting');

before=stage8_k2_rtc_file_sha256(filename);
stage8_k2_rtc_checkpoint_validate(filename,spec,cp.domain,identity,prepared);
assert(strcmp(before,stage8_k2_rtc_file_sha256(filename)) && ~isfile([filename '.tmp']));
for field=["head","source_hash"]
    wrong_identity=identity;
    wrong_identity.(field)='wrong-identity';
    rejected=false;
    try
        stage8_k2_rtc_checkpoint_validate(filename,spec,cp.domain,wrong_identity,prepared);
    catch exception
        rejected=strcmp(exception.identifier,'RTC:CheckpointCode');
    end
    assert(rejected,'RTC:T16','Historical checkpoint identity was accepted.');
end
checkpoint=load(filename,'checkpoint'); checkpoint=checkpoint.checkpoint;
checkpoint.rows.fit_valid(1)=~checkpoint.rows.fit_valid(1);
corrupt=[tempname(fullfile(runtime,'tests')) '.mat']; save(corrupt,'checkpoint','-v7');
rejected=false;
try, stage8_k2_rtc_checkpoint_validate(corrupt,spec,cp.domain,identity,prepared); catch, rejected=true; end
assert(rejected);
record(16,'Atomic checkpoint, read-only resume, corrupt and wrong-identity rejection');
clear elementfits elementdiag
manifest=stage8_k2_rtc_test_plot_only(repo,fixture_dir,fullfile(runtime,'tests','plot_only'));
assert(manifest.figure_count==8);
record(17,'Eight plot-only figures without estimator paths');
controller=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','powershell','Stage8K2RTCController.ps1');
[status,output]=system(sprintf('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%s" -Action Test -RepoDir "%s" -RuntimeRoot "%s"',controller,repo,runtime));
assert(status==0,'RTC:T18','%s',output);
record(18,'Scheduled controller, real launcher/worker Tick, rejected inventories and cleanup');
identity=stage8_k2_rtc_code_identity(repo);
report=struct('pass',true,'test_count',18,'group_count',4, ...
    'groups',{{'A_CONFIGURATION_DEPENDENCIES','B_SNR_METRICS','C_FOUR_SMOKE_OUTPUTS','D_CONTROLLER_WIRING'}},'tests',{vertcat(tests{:})}, ...
    'source_hash',identity.source_hash,'nominal_max_error_db',maximum, ...
    'snr_base_count',c.base_count,'realized_snr_spread_db',realized_spread, ...
    'scale_tolerances',struct('center_deg',1e-4,'axis_vector',1e-6,'rho_deg',1e-3,'angles_fro_deg',1e-3), ...
    'scale_fixture_errors',scale_errors,'scale_valid_count',scale_valid,'runtime_sec',toc(timer));
stage8_k2_rtc_write_json(fullfile(runtime,'controller','gates.json'),report);
stage8_k2_rtc_write_json(fullfile(repo,'innovation-mining','59_stage8_k2_raw_tangent_two_scenarios_preflight.json'),report);
fprintf('FOUR GROUPS PASS; 18 inherited checks\n');

    function record(number,name)
        tests{number}=struct('id',sprintf('T%d',number),'name',name,'pass',true);
        fprintf('T%d PASS: %s\n',number,name);
    end
end

function equivalent(a,b)
assert(a.fit_valid==b.fit_valid && string(a.fit_status)==string(b.fit_status));
assert(isequaln(a.angles_hat_deg,b.angles_hat_deg));
end
