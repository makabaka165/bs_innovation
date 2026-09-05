function report=stage8_k2_rtc_run_tests(repo,runtime)
cleanup=stage8_k2_rtc_add_paths(repo); %#ok<NASGU>
c=stage8_k2_rtc_constants();
prepared=stage8_k2_rtc_prepare(repo,runtime);
ctx=stage8_k2_rtc_build_context(repo);
registry=prepared.registry; widths=prepared.beamwidth;
tests=cell(18,1);
timer=tic;
script=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','powershell','Stage8K2RTCScope.ps1');
[status,output]=system(sprintf('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%s" -RepoDir "%s"',script,repo));
assert(status==0,'RTC:T1','%s',output);
[status,branch]=system('git branch --show-current'); assert(status==0 && strcmp(strtrim(branch),c.branch));
record(1,'Git/worktree identity');

fixtures=registry(registry.replicate_id==1,:);
maximum=zeros(1,2); realized=cell(1,2); first=cell(240,2);
for k=1:height(fixtures)
    spec=fixtures(k,:); clean=stage8_k2_rtc_build_clean_signals(spec,ctx.model);
    observations={stage8_k2_rtc_generate_beamspace_observation(clean.Xw,spec.nominal_snr_db,spec.beam_noise_seed), ...
        stage8_k2_rtc_generate_element_observation(clean.Xe,spec.nominal_snr_db,spec.element_noise_seed)};
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
assert(all(maximum<=1e-12) && all(cellfun(@std,realized)>.01));
record(2,'Beamspace nominal variance and common random numbers');
record(3,'Element nominal variance and independent seeds');

scale_fixtures=registry(registry.replicate_id==1 & registry.nominal_snr_db==22 & ismember(registry.L,[1 8]),:);
assert(height(scale_fixtures)==8);
scale_errors=zeros(8,4); scale_valid=0;
for k=1:8
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
record(4,'Eight scale-equivalence fixtures');

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
for p=1:4
    spec=registry(find(registry.profile_id=="P"+p,1),:); truth=stage8_k2_rtc_build_truth(spec);
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
record(7,'Endpoint permutation invariance'); record(8,'P1-P4 center collapse rejection'); record(9,'Truth endpoint success');

spec=registry(find(registry.profile_id=="P1" & registry.L==8 & registry.nominal_snr_db==22,1),:);
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
[beamfits,beamdiag]=stage8_k2_rtc_fit_beamspace_methods(o.data,ctx.model,ctx.domain,beam_resources,c.core,c.classical);
direct=stage8_k2_cb_full4d_cml(o.data,ctx.model,ctx.domain,'BEAMSPACE',struct(),c.classical);
equivalent(beamfits{2},direct);
assert(direct.coarse_candidate_count==210 && direct.continuous_start_count==6);
compat=c.classical; compat.snr_db_values=0; compat.profile_ids=0;
direct=stage8_k2_cb_music(o.data,beam_resources.entry,beam_resources,'BEAMSPACE',8,compat);
equivalent(beamfits{3},direct);
clear beam_resources
element_resources=stage8_k2_rtc_prepare_resources(ctx.model,ctx.domain,'ELEMENT');
oe=stage8_k2_rtc_generate_element_observation(clean.Xe,spec.nominal_snr_db,spec.element_noise_seed);
[elementfits,elementdiag]=stage8_k2_rtc_fit_element_methods(oe.data,ctx.model,ctx.domain,element_resources,c.classical,c.structured,true(1,3));
whitening=struct('whitener',speye(2080),'method','NATIVE_IID_IDENTITY','whitening_error',0);
direct=stage8_k2_cb_full4d_cml(oe.data,ctx.model,ctx.domain,'ELEMENT',whitening,c.classical);
equivalent(elementfits{1},direct);
direct=stage8_k2_cb_music(oe.data,element_resources.entry,element_resources,'ELEMENT',8,compat);
equivalent(elementfits{2},direct);
R=stage8_k2_sb_vertical_covariance(oe.data,struct('W_az',eye(65),'az_whitening_error',0),c.structured);
[Rfb,Rn]=stage8_k2_sb_fbss_covariance(R,eye(32),c.structured);
for k=1:3
    switch k
        case 1, elevation=stage8_k2_sb_gfbss_music(Rfb,Rn,ctx.model,c.structured);
        case 2, elevation=stage8_k2_sb_root_music(Rfb,ctx.model,c.structured);
        case 3, elevation=stage8_k2_sb_ls_esprit(Rfb,ctx.model,c.structured);
    end
    assert(isequaln(elevation.elevations_hat_deg,elementdiag.elevations{k}.elevations_hat_deg));
    if elevation.fit_valid
        direct=stage8_k2_sb_conditional_az_cml(oe.data,elevation.elevations_hat_deg,ctx.model,whitening,c.structured);
        equivalent(elementfits{k+2},direct);
    else
        assert(~elementfits{k+2}.fit_valid);
    end
end
record(14,'Seven classical wrappers match unchanged direct kernels');
assert(~isfield(ctx.model.array_configuration,'tgt'));
for constants={c.core,c.classical,c.structured}
    assert(~any(contains(lower(string(fieldnames(constants{1}))),["truth","profile","snr","beamwidth","success"])));
end
for file=["fit_core","fit_k1_white","projected_direction","profile_scale_direct","fit_beamspace_methods","fit_element_methods"]
    source=fileread(fullfile(active,"stage8_k2_rtc_"+file+".m"));
    assert(isempty(regexp(source,'\b(truth|profile_id|nominal_snr_db|realized_snr_db|beamwidth|tau_trial_bw)\b','once')));
end
record(15,'Scenario truth, SNR and thresholds isolated from fitting');

fixture_dir=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','tests','fixtures');
if ~isfolder(fixture_dir), mkdir(fixture_dir); end
width=widths(widths.profile_id==spec.profile_id,:);
method_rows=cell(8,1);
for k=1:3, method_rows{k}=stage8_k2_rtc_result_row(spec,c.method_ids(k),o,beamfits{k},clean.truth,width); end
for k=1:5, method_rows{k+3}=stage8_k2_rtc_result_row(spec,c.method_ids(k+3),oe,elementfits{k},clean.truth,width); end
fixture=struct2table(vertcat(method_rows{:}));
writetable(fixture,fullfile(fixture_dir,'58_stage8_k2_raw_tangent_plot_data.csv'));
representatives={struct('spec',spec,'diagnostics',beamdiag)};
save(fullfile(fixture_dir,'58_stage8_k2_raw_tangent_rho_trace_representatives.mat'),'representatives','-v7');
identity=stage8_k2_rtc_code_identity(repo);
cp=struct('spec',spec,'domain','BEAMSPACE','source_hash',clean.source_hash,'truth_hash',clean.truth_hash, ...
    'noise_seed',o.noise_seed,'noise_hash',o.noise_hash,'clean_hash',o.clean_hash,'observation_hash',o.observation_hash, ...
    'snr',rmfield(o,{'data','standard_noise','noise'}),'rows',fixture(1:3,:),'diagnostics',beamdiag, ...
    'code_identity',identity,'registry_hash',prepared.registry_hash,'beamwidth_hash',prepared.beamwidth_hash, ...
    'configuration_hash',prepared.configuration_hash);
filename=[tempname(fullfile(runtime,'tests')) '.mat'];
stage8_k2_rtc_checkpoint_write(filename,cp);
stage8_k2_rtc_checkpoint_validate(filename,spec,'BEAMSPACE',identity,prepared);
before=stage8_k2_rtc_file_sha256(filename);
stage8_k2_rtc_checkpoint_validate(filename,spec,'BEAMSPACE',identity,prepared);
assert(strcmp(before,stage8_k2_rtc_file_sha256(filename)) && ~isfile([filename '.tmp']));
checkpoint=load(filename,'checkpoint'); checkpoint=checkpoint.checkpoint;
checkpoint.rows.fit_valid(1)=~checkpoint.rows.fit_valid(1);
corrupt=[tempname(fullfile(runtime,'tests')) '.mat']; save(corrupt,'checkpoint','-v7');
rejected=false;
try, stage8_k2_rtc_checkpoint_validate(corrupt,spec,'BEAMSPACE',identity,prepared); catch, rejected=true; end
assert(rejected);
record(16,'Atomic checkpoint, read-only resume and corrupt rejection');
clear element_resources elementfits elementdiag
manifest=stage8_k2_rtc_test_plot_only(repo,fixture_dir,fullfile(runtime,'tests','plot_only'));
assert(manifest.figure_count==12);
record(17,'Twelve plot-only figures without estimator paths');
controller=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','powershell','Stage8K2RTCController.ps1');
[status,output]=system(sprintf('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%s" -Action Test -RepoDir "%s" -RuntimeRoot "%s"',controller,repo,runtime));
assert(status==0,'RTC:T18','%s',output);
record(18,'Scheduled controller transition, resume and cleanup contract');
identity=stage8_k2_rtc_code_identity(repo);
report=struct('pass',true,'test_count',18,'tests',{vertcat(tests{:})}, ...
    'source_hash',identity.source_hash,'nominal_max_error_db',maximum, ...
    'scale_tolerances',struct('center_deg',1e-4,'axis_vector',1e-6,'rho_deg',1e-3,'angles_fro_deg',1e-3), ...
    'scale_fixture_errors',scale_errors,'scale_valid_count',scale_valid,'runtime_sec',toc(timer));
stage8_k2_rtc_write_json(fullfile(runtime,'controller','gates.json'),report);
stage8_k2_rtc_write_json(fullfile(repo,'innovation-mining','58_stage8_k2_raw_tangent_fixed_tests.json'),report);
fprintf('18/18 PASS\n');

    function record(number,name)
        tests{number}=struct('id',sprintf('T%d',number),'name',name,'pass',true);
        fprintf('T%d PASS: %s\n',number,name);
    end
end

function equivalent(a,b)
assert(a.fit_valid==b.fit_valid && string(a.fit_status)==string(b.fit_status));
assert(isequaln(a.angles_hat_deg,b.angles_hat_deg));
end
