function difference_deg = stage8_k2_mc_periodic_difference(a_deg, b_deg)
%STAGE8_K2_MC_PERIODIC_DIFFERENCE Return a-b in [-180,180).

difference_deg = mod(double(a_deg) - double(b_deg) + 180, 360) - 180;
end
