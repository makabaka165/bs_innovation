function m = stage8_k2_rtc_resolution_metrics(estimate, truth, widths, valid)
bw = [widths.az_bw_3db_deg widths.el_bw_3db_deg];
assert(all(isfinite(bw) & bw > 0));
true_delta = truth(2,:) - truth(1,:);
rho = norm(true_delta);
m = struct('best_permutation_id', NaN, 'd_max_deg', NaN, 'd_max_bw', NaN, ...
    'tau_trial_bw', min(.1, .4*norm(true_delta./bw)), ...
    'localization_success_01bw', false, 'resolution_success', false, ...
    'joint_RMSE_deg', NaN, 'azimuth_RMSE_deg', NaN, 'elevation_RMSE_deg', NaN, ...
    'center_error_deg', NaN, 'axis_error_deg', NaN, 'rho_true_deg', rho, ...
    'rho_hat_deg', NaN, 'rho_error_deg', NaN, 'rho_relative_error', NaN, ...
    'separation_vector_error_deg', NaN);
if ~valid, return; end
assert(isequal(size(estimate), [2 2]) && all(isfinite(estimate(:))));
permutations = [1 2; 2 1];
max_bw = zeros(2,1); max_deg = zeros(2,1); square_error = zeros(2,1);
for p = 1:2
    delta = estimate(permutations(p,:),:) - truth;
    max_bw(p) = max(sqrt(sum((delta./bw).^2, 2)));
    max_deg(p) = max(sqrt(sum(delta.^2, 2)));
    square_error(p) = sum(delta(:).^2);
end
[m.d_max_bw, m.best_permutation_id] = min(max_bw);
m.d_max_deg = min(max_deg);
[~, p] = min(square_error);
aligned = estimate(permutations(p,:),:);
delta = aligned-truth;
m.joint_RMSE_deg = sqrt(sum(delta(:).^2)/2);
m.azimuth_RMSE_deg = sqrt(mean(delta(:,1).^2));
m.elevation_RMSE_deg = sqrt(mean(delta(:,2).^2));
m.center_error_deg = norm(mean(estimate,1)-mean(truth,1));
hat_delta = estimate(2,:)-estimate(1,:);
m.rho_hat_deg = norm(hat_delta);
m.rho_error_deg = abs(m.rho_hat_deg-rho);
m.rho_relative_error = m.rho_error_deg/rho;
m.separation_vector_error_deg = min(norm(hat_delta-true_delta), norm(hat_delta+true_delta));
if m.rho_hat_deg > 1e-12
    m.axis_error_deg = acosd(min(1,max(0,abs(dot(hat_delta,true_delta))/(m.rho_hat_deg*rho))));
end
m.localization_success_01bw = m.d_max_bw <= .1;
m.resolution_success = m.d_max_bw <= m.tau_trial_bw;
end
