function value = stage8_type1_quantile(samples, probability)
%STAGE8_TYPE1_QUANTILE Return the inverse empirical CDF order statistic.

samples = samples(:);
if isempty(samples) || any(~isfinite(samples)) || ...
        ~(isscalar(probability) && probability > 0 && probability < 1)
    error('stage8_type1_quantile:Inputs', ...
        'Samples must be finite and probability must lie strictly in (0,1).');
end
ordered = sort(samples, 'ascend');
index = max(1, ceil(numel(ordered) * probability));
value = ordered(index);
end
