function truth = stage8_k2_snr_truth_from_spec(spec)
%STAGE8_K2_SNR_TRUTH_FROM_SPEC Reconstruct the registered K2 endpoints.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_k2_snr_truth_from_spec:Spec', ...
        'spec must be one registered trial row.');
end
direction = [cosd(spec.direction_deg), sind(spec.direction_deg)];
center = [spec.center_az_deg, spec.center_el_deg];
truth = [center - spec.separation_deg * direction / 2; ...
    center + spec.separation_deg * direction / 2];
end
