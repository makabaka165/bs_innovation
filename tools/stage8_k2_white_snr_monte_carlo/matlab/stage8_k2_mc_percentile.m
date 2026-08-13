function value = stage8_k2_mc_percentile(values, percentile)
%STAGE8_K2_MC_PERCENTILE Linear-interpolation finite percentile.

values = sort(double(values(isfinite(values))));
if isempty(values)
    value = NaN;
elseif numel(values) == 1
    value = values(1);
else
    position = 1 + (numel(values) - 1) * percentile / 100;
    lower_index = floor(position);
    upper_index = ceil(position);
    weight = position - lower_index;
    value = (1 - weight) * values(lower_index) + ...
        weight * values(upper_index);
end
end
