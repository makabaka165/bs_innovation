function output = stage8_k2_mc_run_static(fixture)
%STAGE8_K2_MC_RUN_STATIC Gate A geometry, production, and negatives.

spec = fixture.spec;
cfg = spec.cfg;
phi = double(spec.reference_pool.array_meta.phiCol);
geometry_rows = repmat(struct('center_column',0,'requested_center_az_deg',NaN, ...
    'physical_center_az_deg',NaN,'rotation_delta_deg',NaN, ...
    'geometry_relative_error',NaN,'steering_relative_error',NaN,'pass',false), ...
    spec.Naz, 1);
az_count = numel(spec.relative_registered_delta_deg);
el_count = numel(spec.elevation_registered_grid_deg);
relative_deltas = spec.relative_registered_delta_deg( ...
    unique([1, ceil(az_count / 2), az_count]));
elevations = spec.elevation_registered_grid_deg( ...
    unique([1, ceil(el_count / 2), el_count]));
for column = 1:spec.Naz
    offset = mod(column - spec.reference_center_column + spec.Naz / 2, ...
        spec.Naz) - spec.Naz / 2;
    delta = stage8_k2_mc_periodic_difference(phi(column), ...
        spec.reference_physical_center_az_deg);
    requested = spec.reference_requested_center_az_deg + delta;
    center = stage8_k2_mc_select_centers(spec, offset);
    center = center(1);
    center.center_column = column;
    center.physical_center_az_deg = phi(column);
    center.physical_center_unwrapped_az_deg = ...
        spec.reference_physical_center_az_deg + delta;
    center.requested_center_az_deg = requested;
    center.rotation_delta_deg = delta;
    pool = stage8_k2_mc_build_rotated_candidate_pool(spec, center);
    canonical = canonical_coordinates_local(pool.array_meta, delta);
    reference = canonical_coordinates_local(spec.reference_pool.array_meta, 0);
    geom_error = relative_error_local(canonical, reference);
    steering_error = 0;
    for d = relative_deltas
        for e = elevations
            a0 = build_receive_cyl_steering_vec( ...
                spec.reference_pool.array_meta.XAct, spec.reference_pool.array_meta.YAct, ...
                spec.reference_pool.array_meta.ZAct, ...
                spec.reference_physical_center_az_deg + d, e, cfg.arr.lambda);
            ac = build_receive_cyl_steering_vec(pool.array_meta.XAct, pool.array_meta.YAct, ...
                pool.array_meta.ZAct, center.physical_center_unwrapped_az_deg + d, e, cfg.arr.lambda);
            a0 = reshape_cyl_vector_to_matrix(a0, spec.reference_pool.array_meta); a0 = a0(:);
            ac = reshape_cyl_vector_to_matrix(ac, pool.array_meta); ac = ac(:);
            steering_error = max(steering_error, relative_error_local(ac, a0));
        end
    end
    geometry_rows(column) = struct('center_column',column, ...
        'requested_center_az_deg',requested, 'physical_center_az_deg',phi(column), ...
        'rotation_delta_deg',delta, 'geometry_relative_error',geom_error, ...
        'steering_relative_error',steering_error, ...
        'pass',geom_error <= 1e-13 && steering_error <= 1e-13);
end
if ~all([geometry_rows.pass])
    error('stage8_k2_mc_run_static:Geometry', 'BLOCKED_LOCAL_ELEMENT_ORDER_MISMATCH.');
end
production_rows = cell(fixture.model_count,1); row_index = 0;
for noise_index = 1:numel(fixture.noise_profile_ids)
    for center_index = 1:fixture.center_count
        bundle = fixture.bundles(center_index, noise_index);
        provider = fixture.providers(noise_index);
        adapter = fixture.adapters(center_index, noise_index);
        [val, metrics] = production_metrics_local(bundle, fixture.bundles(1,noise_index), provider, adapter);
        row_index = row_index + 1;
        production_rows{row_index} = struct('center_offset',bundle.center.column_offset, ...
            'center_column',bundle.center.center_column, 'noise_profile_id',string(bundle.noise_profile_id), ...
            'rotation_class_hash',string(bundle.identity.rotation_class_hash), ...
            'actual_center_hash',string(bundle.identity.actual_center_hash), ...
            'geometry_error',metrics.geometry_error, 'W_error',metrics.W_error, ...
            'C_error',metrics.C_error, 'T_error',metrics.T_error, 'G_error',metrics.G_error, ...
            'rank_mismatch',metrics.rank_mismatch, 'pass',val);
    end
end
production = struct2table(vertcat(production_rows{:}));
negative = negative_controls_local(fixture);
output = struct('schema_version','STAGE8_K2_MC_STATIC_V1', ...
    'geometry',struct2table(geometry_rows), 'production',production, ...
    'negative_controls',negative, 'geometry_pass',all([geometry_rows.pass]), ...
    'production_pass',all(production.pass), 'negative_pass',all(negative.pass), ...
    'status','STAGE8_K2_MULTICENTER_STATIC_ROTATION_PASS');
if ~(output.geometry_pass && output.production_pass && output.negative_pass)
    error('stage8_k2_mc_run_static:Failed', ...
        'Gate A static validation failed.');
end
end

function [pass, metrics] = production_metrics_local(bundle, reference_bundle, provider, adapter)
metrics = struct('geometry_error',bundle.identity.canonical_geometry_relative_error, ...
    'W_error',bundle.debug.W_relative_error,'C_error',bundle.debug.C_relative_error, ...
    'T_error',bundle.debug.T_relative_error,'G_error',0,'rank_mismatch',0);
keys = sortrows(bundle.local_domain.candidate_points_deg,[1,2]);
for i=1:size(keys,1)
    [g,~] = stage8_k2_mc_get_manifold(keys(i,:),bundle.model,bundle.local_domain,provider,adapter);
    [d,~] = stage8_k2_tcc_build_g_direct(keys(i,:),bundle.model,struct());
    metrics.G_error=max(metrics.G_error,relative_error_local(g,d));
    [rg,~,~]=stage8_k2_tcc_stable_matrix_rank(g,1); [rd,~,~]=stage8_k2_tcc_stable_matrix_rank(d,1);
    metrics.rank_mismatch=metrics.rank_mismatch+double(rg~=rd);
end
for i=1:size(keys,1)
    for j=i:size(keys,1)
        pair=[keys(i,:);keys(j,:)];
        [g,~] = stage8_k2_mc_get_manifold(pair,bundle.model, ...
            bundle.local_domain,provider,adapter);
        [d,~] = stage8_k2_tcc_build_g_direct(pair,bundle.model,struct());
        metrics.G_error=max(metrics.G_error,relative_error_local(g,d));
        [rg,sg,tg]=stage8_k2_tcc_stable_matrix_rank(g,1);
        [rd,sd,td]=stage8_k2_tcc_stable_matrix_rank(d,1);
        metrics.rank_mismatch=metrics.rank_mismatch+double(rg~=rd || ...
            relative_error_local(sg,sd)>1e-10 || ...
            abs(tg-td)/max([1,abs(tg),abs(td)])>1e-10);
    end
end
pass=metrics.geometry_error<=1e-13 && metrics.W_error<=1e-11 && metrics.C_error<=1e-11 && ...
    metrics.T_error<=1e-10 && metrics.G_error<=1e-10 && metrics.rank_mismatch==0;
end

function rows = negative_controls_local(fixture)
ref=fixture.bundles(1,1); c=fixture.centers(2);
cases={'UNSHIFTED_BEAM', 'REQUESTED_CENTER_AS_PHYSICAL', 'GEOMETRY_PERTURBATION'};
pass=false(3,1); metric=NaN(3,1); messages=strings(3,1);
for i=1:3
    switch i
        case 1
            [badpool,badcfg]=stage8_k2_mc_build_rotated_candidate_pool( ...
                fixture.spec,c);
            [~,bad_U]=form_azimuth_dbf_cube(complex(zeros( ...
                numel(badpool.elevation_beam_deg),fixture.spec.cfg.beam.subNaz)), ...
                fixture.spec.reference_pool.azimuth_beam_deg, ...
                badpool.elevation_beam_deg,badcfg);
            [bad_W,~]=build_sequential_beam_matrix( ...
                badpool.V,bad_U,badpool.array_meta);
            metric(i)=relative_error_local(bad_W(:,ref.model.channels), ...
                ref.model.Wseq);
            pass(i)=metric(i)>1e-6;
            messages(i)="BLOCKED_ROTATED_BEAM_LAYOUT_MISMATCH";
        case 2
            metric(i)=abs(c.requested_center_az_deg - ...
                c.physical_center_az_deg);
            pass(i)=metric(i)>1e-9;
            messages(i)="BLOCKED_PHYSICAL_CENTER_SELECTION_MISMATCH";
        case 3
            bundle=fixture.bundles(2,1); bad_model=bundle.model;
            bad_model.array_meta.XAct(1)=bad_model.array_meta.XAct(1)+1e-3;
            bad_model.array_meta.xActVec=bad_model.array_meta.XAct(:);
            angle=bundle.local_domain.candidate_points_deg(1,:);
            good=build_full_sequential_local_manifold(angle,bundle.model,struct());
            wrong=build_full_sequential_local_manifold(angle,bad_model,struct());
            metric(i)=relative_error_local(wrong,good);
            pass(i)=metric(i)>1e-9;
            messages(i)="BLOCKED_LOCAL_ELEMENT_ORDER_MISMATCH";
    end
end
rows=table(string(cases(:)),pass,metric,messages,'VariableNames',{'control_id','pass','metric','message'});
end

function value=canonical_coordinates_local(meta,delta)
x=double(meta.XAct.'); y=double(meta.YAct.'); z=double(meta.ZAct.');
value=round([cosd(delta)*x+sind(delta)*y, -sind(delta)*x+cosd(delta)*y,z],13); value(value==0)=0;
end
function value=relative_error_local(a,b), value=norm(a-b,'fro')/max(norm(b,'fro'),realmin); end
