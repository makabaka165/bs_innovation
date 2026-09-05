function result = stage8_k2_rtc_profile_scale_direct(Z, model, center, direction, domain, c)
direction = direction(:).'/norm(direction);
bounds = domain.domain_bounds_deg;
distance = min(center-[bounds(1) bounds(3)], [bounds(2) bounds(4)]-center);
limits = Inf(1,2);
nonzero = abs(direction) > eps;
limits(nonzero) = 2*distance(nonzero)./abs(direction(nonzero));
rho_max = min(limits);
template = struct('rho_deg',NaN,'angles_deg',NaN(2,2),'requested_rank',2, ...
    'valid',false,'status','NOT_RUN','score',NaN,'rss',NaN,'loglik',-Inf,'effective_rank',0);
result = struct('valid',false,'status','TANGENT_PROFILE_NO_FEASIBLE_SCALE', ...
    'rho_hat_deg',NaN,'rho_max_deg',rho_max,'angles_hat_deg',NaN(2,2), ...
    'rss',NaN,'loglik_concentrated',NaN,'effective_rank',0, ...
    'score_call_count',0,'svd_call_count',0,'scan_nodes_deg',[], ...
    'full_manifold_used_flag',true,'trace',repmat(template,0,1));
if ~(isfinite(rho_max) && rho_max >= c.rho_min_deg), return; end
nodes = linspace(c.rho_min_deg,rho_max,c.scan_node_count);
result.scan_nodes_deg = nodes;
evaluations = repmat(template,0,1);
scan = repmat(template,numel(nodes),1);
for k = 1:numel(nodes), scan(k) = evaluate(nodes(k)); end
valid = find([scan.valid]);
if isempty(valid)
    result.status = 'TANGENT_PROFILE_NO_VALID_SCAN_NODE';
    result.trace = evaluations;
    return;
end
[~,best] = max([scan(valid).loglik]);
best = valid(best);
bracket = nodes([max(1,best-1),min(numel(nodes),best+1)]);
optimum = nodes(best);
if bracket(2) > bracket(1)
    options = optimset('TolX',c.fminbnd_TolX_deg,'MaxFunEvals',c.fminbnd_MaxFunEvals,'Display','off');
    optimum = fminbnd(@objective,bracket(1),bracket(2),options);
end
candidates = [nodes(best) bracket optimum];
final = repmat(template,numel(candidates),1);
for k = 1:numel(candidates), final(k) = evaluate(candidates(k)); end
valid = find([final.valid]);
result.trace = evaluations;
if isempty(valid)
    result.status = 'TANGENT_PROFILE_FINAL_CANDIDATE_INVALID';
    return;
end
[~,best] = max([final(valid).loglik]);
chosen = final(valid(best));
result.valid = true;
result.status = 'TANGENT_PROFILE_VALID';
result.rho_hat_deg = chosen.rho_deg;
result.angles_hat_deg = chosen.angles_deg;
result.rss = chosen.rss;
result.loglik_concentrated = chosen.loglik;
result.effective_rank = chosen.effective_rank;

    function value = objective(rho)
        e = evaluate(rho);
        value = realmax/16;
        if e.valid, value = -e.loglik; end
    end
    function e = evaluate(rho)
        previous = find([evaluations.rho_deg] == rho,1);
        if ~isempty(previous), e = evaluations(previous); return; end
        e = template;
        e.rho_deg = rho;
        e.angles_deg = sortrows([center-rho*direction/2;center+rho*direction/2],[2 1]);
        a = e.angles_deg;
        tolerance = 64*eps(max(abs(bounds)));
        inside = all(a(:,1)>=bounds(1)-tolerance & a(:,1)<=bounds(2)+tolerance & ...
            a(:,2)>=bounds(3)-tolerance & a(:,2)<=bounds(4)+tolerance);
        if ~inside
            e.status = 'ENDPOINT_OUTSIDE_DOMAIN';
        else
            [G,~,info] = build_full_sequential_local_manifold(a,model,struct('rank_multiplier',c.rank_multiplier));
            result.svd_call_count = result.svd_call_count+info.num_svd;
            if info.rank_Gseq < 2
                e.status = 'K2_MANIFOLD_RANK_DEFICIENT';
            else
                [e.score,e.rss,variance,e.loglik,e.effective_rank] = concentrated_dml_rss(Z,G, ...
                    struct('requested_rank',2,'rank_multiplier',c.rank_multiplier,'compute_projector_checks',false));
                result.score_call_count = result.score_call_count+1;
                result.svd_call_count = result.svd_call_count+1;
                e.valid = e.effective_rank == 2 && all(isfinite([e.score e.rss variance e.loglik])) && e.rss>=0;
                e.status = 'INVALID_FULL_MANIFOLD_K2_SCORE';
                if e.valid, e.status = 'VALID_FULL_MANIFOLD_K2_SCORE'; end
            end
        end
        evaluations(end+1,1) = e;
    end
end
