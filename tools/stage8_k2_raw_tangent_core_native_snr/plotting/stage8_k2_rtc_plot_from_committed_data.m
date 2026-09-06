function manifest = stage8_k2_rtc_plot_from_committed_data(data_dir, output_dir)
% This entry point depends only on exported tables/traces and MATLAB graphics.
prefix='60_stage8_k2_raw_tangent_two_scenarios_';
data_file=fullfile(data_dir,[prefix 'plot_data.csv']);
trace_file=fullfile(data_dir,[prefix 'rho_trace_representatives.mat']);
t=readtable(data_file,'TextType','string');
loaded=load(trace_file,'representatives');
assert(all(t.L==8) && all(ismember(t.profile_id,["SC_A","SC_B"])));
if ~isfolder(output_dir), mkdir(output_dir); end
profiles=["SC_A","SC_B"]; outputs=cell(numel(profiles)*4,1); index=0;
beam=["TANGENT_PROFILE_CORE","FULL4D_BEAMSPACE_CML_MULTISTART","BEAMSPACE_MUSIC_K2"];
element=["FULL4D_ELEMENT_CML_MULTISTART","ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML"];
for p=1:numel(profiles)
    s=t(t.profile_id==profiles(p),:);
    core=s(s.method_id==beam(1),:);
    for kind=1:4
        index=index+1;
        f=figure('Visible','off','Color','w','Position',[80 80 1320 820]);
        cleanup=onCleanup(@() close(f));
        switch kind
            case 1
                suffix='beamspace_rates';
                tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
                metrics=["fit_valid","localization_success_01bw","resolution_success"];
                labels=["Numerical validity","Endpoint localization","Strict resolution"];
                for panel=1:3
                    nexttile;
                    for method=beam
                        curve(s(s.method_id==method,:),metrics(panel),'rate',method_label(method),'BEAMSPACE');
                    end
                    title(labels(panel)); ylabel('Count / all trials'); ylim([0 1]);
                    legend('Location','best');
                end
            case 2
                suffix='beamspace_errors';
                tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
                for method=beam
                    nexttile;
                    subset=s(s.method_id==method,:);
                    curve(subset,'joint_RMSE_deg','median','Median','BEAMSPACE');
                    curve(subset,'joint_RMSE_deg','p90','P90','BEAMSPACE');
                    title(method_label(method)); ylabel('Joint RMSE (deg), valid fits'); legend('Location','best');
                end
                for method=beam
                    nexttile;
                    curve(s(s.method_id==method,:),'fit_valid','count','Valid count','BEAMSPACE');
                    title(method_label(method)); ylabel('Valid samples'); ylim([0 max(1,max_cell_count(s))]);
                end
            case 3
                suffix='element_reference';
                tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
                metrics=["fit_valid","localization_success_01bw","resolution_success"];
                labels=["Numerical validity","Endpoint localization","Strict resolution"];
                for panel=1:3
                    nexttile;
                    for method=element
                        curve(s(s.method_id==method,:),metrics(panel),'rate',method_label(method),'ELEMENT');
                    end
                    title(labels(panel)); ylabel('Count / all trials'); ylim([0 1]); legend('Location','best');
                end
                for method=element
                    nexttile;
                    subset=s(s.method_id==method,:);
                    curve(subset,'joint_RMSE_deg','median','Median','ELEMENT');
                    curve(subset,'joint_RMSE_deg','p90','P90','ELEMENT');
                    title(method_label(method)); ylabel('Joint RMSE (deg), valid fits'); legend('Location','best');
                end
                nexttile;
                for method=element
                    curve(s(s.method_id==method,:),'fit_valid','count',method_label(method),'ELEMENT');
                end
                title('Valid sample counts'); ylabel('Valid samples'); ylim([0 max(1,max_cell_count(s))]); legend('Location','best');
            case 4
                suffix='tangent_diagnostics';
                tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
                nexttile;
                curve(core,'axis_error_deg','median','Median','BEAMSPACE');
                curve(core,'axis_error_deg','p90','P90','BEAMSPACE');
                ylabel('Axis error (deg)'); title('Tangent axis, valid fits'); legend('Location','best');
                nexttile;
                curve(core,'rho_error_deg','median','Median','BEAMSPACE');
                curve(core,'rho_error_deg','p90','P90','BEAMSPACE');
                ylabel('Separation error (deg)'); title('Tangent separation, valid fits'); legend('Location','best');
                nexttile;
                reasons=unique(core.fit_status);
                counts=zeros(numel(reasons),1);
                for k=1:numel(reasons), counts(k)=nnz(core.fit_status==reasons(k)); end
                barh(counts); yticks(1:numel(reasons)); yticklabels(strrep(reasons,'_',' '));
                xlabel('Trial count'); title('Tangent status counts, including valid'); grid on;
                nexttile; hold on;
                matching=cellfun(@(v) v.spec.profile_id==profiles(p),loaded.representatives);
                examples=loaded.representatives(matching); drawn=false;
                for k=1:numel(examples)
                    item=examples{k};
                    if ~isfield(item.diagnostics.scale,'trace'), continue; end
                    trace=item.diagnostics.scale.trace;
                    if isempty(trace), continue; end
                    valid=[trace.valid];
                    if ~any(valid), continue; end
                    rho=[trace(valid).rho_deg]; ll=[trace(valid).loglik];
                    [rho,order]=sort(rho);
                    plot(rho,ll(order)-max(ll),'DisplayName',sprintf('%g dB',item.spec.nominal_snr_db));
                    drawn=true;
                end
                if ~drawn, text(.5,.5,'No valid scale trace','HorizontalAlignment','center'); end
                xlabel('Separation scale (deg)'); ylabel('Log likelihood relative to maximum');
                title('Replicate 1: full-manifold profiles'); grid on;
                if drawn, legend('Location','best'); end
        end
        sgtitle(strrep(profiles(p),'_',' ')+", L=8: "+strrep(suffix,'_',' '),'FontSize',14);
        axes_list=findall(f,'Type','axes');
        set(axes_list,'FontSize',10,'TickLabelInterpreter','none');
        name="60_"+profiles(p)+"_"+suffix+".png";
        filename=fullfile(output_dir,name);
        exportgraphics(f,filename,'Resolution',150);
        pixels=imread(filename);
        assert(std(double(pixels(:)))>1,'RTC:BlankPlot','Blank plot: %s',filename);
        outputs{index}=struct('path',char(name),'sha256',file_hash(filename), ...
            'width',size(pixels,2),'height',size(pixels,1));
        clear cleanup
    end
end
manifest=struct('title','SC_A / SC_B, L=8, native-domain SNR','plot_only',true, ...
    'input_data_sha256',file_hash(data_file),'input_trace_sha256',file_hash(trace_file), ...
    'figure_count',index,'figures',{vertcat(outputs{:})});
end

function curve(t, metric, statistic, label, domain)
snr=unique(t.nominal_snr_db);
values=NaN(size(snr));
for k=1:numel(snr)
    s=t(t.nominal_snr_db==snr(k),:);
    if strcmp(statistic,'rate')
        if height(s)>0, values(k)=nnz(s.(metric))/height(s); end
    elseif strcmp(statistic,'count')
        values(k)=nnz(s.(metric));
    else
        sample=s.(metric)(s.fit_valid & isfinite(s.(metric)));
        if ~isempty(sample)
            if strcmp(statistic,'p90'), values(k)=prctile(sample,90); else, values(k)=median(sample); end
        end
    end
end
style='-o'; if strcmp(statistic,'p90'), style='--s'; end
plot(snr,values,style,'LineWidth',1.4,'MarkerSize',4,'DisplayName',char(label)); hold on;
if all(isnan(values)) && isempty(findobj(gca,'Tag','no_valid_samples'))
    text(.05,.92,'No valid samples','Units','normalized','FontSize',9,'Tag','no_valid_samples');
end
xlabel(string(domain)+"-native nominal SNR (dB)"); grid on;
end

function count=max_cell_count(t)
[groups,~]=findgroups(t(:,{'method_id','nominal_snr_db'}));
count=max(accumarray(groups,1));
end

function label=method_label(method)
switch method
    case "TANGENT_PROFILE_CORE", label='Tangent';
    case "FULL4D_BEAMSPACE_CML_MULTISTART", label='Beamspace Full4D CML';
    case "BEAMSPACE_MUSIC_K2", label='Beamspace MUSIC';
    case "FULL4D_ELEMENT_CML_MULTISTART", label='Element Full4D CML';
    case "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML", label='FBSS Root + azimuth CML';
end
end

function digest=file_hash(filename)
fid=fopen(filename,'rb'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid));
bytes=fread(fid,Inf,'*uint8');
md=java.security.MessageDigest.getInstance('SHA-256'); md.update(typecast(bytes,'int8'));
digest=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
