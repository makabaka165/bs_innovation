function truth = stage8_k2_cb_truth_from_spec(spec)
%STAGE8_K2_CB_TRUTH_FROM_SPEC Return registered truth for evaluation only.

direction = [cosd(spec.direction_deg), sind(spec.direction_deg)];
center = [spec.center_az_deg, spec.center_el_deg];
truth = [center - spec.separation_deg * direction / 2; ...
    center + spec.separation_deg * direction / 2];
end
