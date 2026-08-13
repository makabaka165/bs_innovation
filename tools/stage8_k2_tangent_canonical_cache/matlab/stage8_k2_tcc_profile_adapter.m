function result = stage8_k2_tcc_profile_adapter( ...
    Z_white, model, center_deg, direction_hat, local_domain, constants, provider)
%STAGE8_K2_TCC_PROFILE_ADAPTER Keep the profile call explicit and small.

if nargin < 7
    provider = [];
end
if isempty(provider)
    result = stage8_k2_tp_profile_scale(Z_white, model, center_deg, ...
        direction_hat, local_domain, constants);
else
    result = stage8_k2_tp_profile_scale(Z_white, model, center_deg, ...
        direction_hat, local_domain, constants, provider);
end
end
