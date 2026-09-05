function angles = stage8_k2_rtc_build_truth(spec)
center = [spec.center_az_deg spec.center_el_deg];
delta = spec.rho_true_deg * [cosd(spec.direction_deg) sind(spec.direction_deg)];
angles = [center - delta/2; center + delta/2];
end
