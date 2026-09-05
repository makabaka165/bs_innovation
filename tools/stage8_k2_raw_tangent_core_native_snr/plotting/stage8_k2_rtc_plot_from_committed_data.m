function manifest = stage8_k2_rtc_plot_from_committed_data(data_dir, output_dir)
% This entry point depends only on committed tables/traces and MATLAB graphics.
data_file=fullfile(data_dir,'58_stage8_k2_raw_tangent_plot_data.csv');
trace_file=fullfile(data_dir,'58_stage8_k2_raw_tangent_rho_trace_representatives.mat');
t=readtable(data_file,'TextType','string');
loaded=load(trace_file,'representatives');
if ~isfolder(output_dir), mkdir(output_dir); end
names=["58_raw_tangent_valid_rate_vs_beam_snr", ...
    "58_raw_tangent_localization_success_vs_beam_snr", ...
    "58_raw_tangent_resolution_success_vs_beam_snr", ...
    "58_raw_tangent_rmse_vs_beam_snr", "58_raw_tangent_success_by_profile", ...
    "58_raw_tangent_success_by_L", "58_beamspace_native_methods_success", ...
    "58_element_native_methods_success", "58_native_domain_rmse_comparison", ...
    "58_raw_tangent_failure_reasons", "58_raw_tangent_axis_rho_errors", ...
    "58_raw_tangent_representative_profiles"];
core=t(t.method_id=="TANGENT_PROFILE_CORE",:);
outputs=cell(12,1);
for figure_index=1:12
    f=figure('Visible','off','Color','w','Position',[100 100 1100 700]);
    cleanup=onCleanup(@() close(f));
    switch figure_index
        case {1,2,3}
            metrics=["fit_valid","localization_success_01bw","resolution_success"];
            labels=["Numerical valid rate","Endpoint localization rate","Strict resolution rate"];
            curve(core,metrics(figure_index),'rate','Raw Tangent Core');
            ylabel(labels(figure_index)); ylim([0 1]);
        case 4
            curve(core,'joint_RMSE_deg','median','Median');
            curve(core,'joint_RMSE_deg','p90','P90');
            ylabel('Joint angular RMSE (deg), valid fits');
        case 5
            for p=unique(core.profile_id).'
                curve(core(core.profile_id==p,:),'resolution_success','rate',p);
            end
            ylabel('Strict resolution rate'); ylim([0 1]);
        case 6
            for L=unique(core.L).'
                curve(core(core.L==L,:),'resolution_success','rate',"L="+L);
            end
            ylabel('Strict resolution rate'); ylim([0 1]);
        case {7,8,9}
            selected=t;
            if figure_index==7, selected=t(t.domain=="BEAMSPACE",:); end
            if figure_index==8, selected=t(t.domain=="ELEMENT",:); end
            for method=unique(selected.method_id,'stable').'
                subset=selected(selected.method_id==method,:);
                if figure_index==9
                    curve(subset,'joint_RMSE_deg','median',method);
                else
                    curve(subset,'resolution_success','rate',method);
                end
            end
            if figure_index==9, ylabel('Median joint RMSE (deg), valid fits');
            else, ylabel('Strict resolution rate'); ylim([0 1]); end
        case 10
            reasons=unique(core.fit_status(~core.fit_valid));
            if isempty(reasons), reasons="NO_ALGORITHMIC_FAILURE"; end
            counts=zeros(numel(reasons),1);
            for k=1:numel(reasons), counts(k)=nnz(core.fit_status==reasons(k)); end
            barh(counts); yticks(1:numel(reasons)); yticklabels(strrep(reasons,'_',' '));
            xlabel('Trial count');
        case 11
            tiledlayout(1,2,'Padding','compact');
            nexttile; curve(core,'axis_error_deg','median','Median'); curve(core,'axis_error_deg','p90','P90'); ylabel('Axis error (deg)');
            nexttile; curve(core,'rho_error_deg','median','Median'); curve(core,'rho_error_deg','p90','P90'); ylabel('Separation error (deg)');
        case 12
            tiledlayout(2,2,'Padding','compact');
            for p=1:4
                nexttile; hold on;
                matching=cellfun(@(v) v.spec.profile_id=="P"+p && v.spec.L==8,loaded.representatives);
                examples=loaded.representatives(matching);
                drawn=false;
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
                title("P"+p+", L=8, replicate=1"); grid on;
                if drawn, legend('Location','best'); end
            end
    end
    if ~ismember(figure_index,[10 11 12])
        xlabel('Native-domain nominal SNR (dB)'); grid on; legend('Location','best','Interpreter','none');
    end
    sgtitle('Native-domain nominal-SNR comparison','FontSize',14);
    axes_list=findall(f,'Type','axes');
    set(axes_list,'FontSize',10,'TickLabelInterpreter','none');
    filename=fullfile(output_dir,names(figure_index)+".png");
    exportgraphics(f,filename,'Resolution',150);
    pixels=imread(filename);
    assert(std(double(pixels(:)))>1,'RTC:BlankPlot','Blank plot: %s',filename);
    outputs{figure_index}=struct('path',char(names(figure_index)+".png"), ...
        'sha256',file_hash(filename),'width',size(pixels,2),'height',size(pixels,1));
    clear cleanup
end
manifest=struct('title','Native-domain nominal-SNR comparison','plot_only',true, ...
    'input_data_sha256',file_hash(data_file),'input_trace_sha256',file_hash(trace_file), ...
    'figure_count',12,'figures',{vertcat(outputs{:})});
end

function curve(t, metric, statistic, label)
snr=unique(t.nominal_snr_db);
values=NaN(size(snr));
for k=1:numel(snr)
    s=t(t.nominal_snr_db==snr(k),:);
    if strcmp(statistic,'rate')
        if nnz(s.applicable)>0, values(k)=nnz(s.(metric))/nnz(s.applicable); end
    else
        sample=s.(metric)(s.fit_valid & isfinite(s.(metric)));
        if ~isempty(sample)
            if strcmp(statistic,'p90'), values(k)=prctile(sample,90); else, values(k)=median(sample); end
        end
    end
end
plot(snr,values,'-o','LineWidth',1.4,'MarkerSize',4,'DisplayName',char(label)); hold on;
xlabel('Native-domain nominal SNR (dB)'); grid on;
end

function digest=file_hash(filename)
fid=fopen(filename,'rb'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid));
bytes=fread(fid,Inf,'*uint8');
md=java.security.MessageDigest.getInstance('SHA-256'); md.update(typecast(bytes,'int8'));
digest=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
