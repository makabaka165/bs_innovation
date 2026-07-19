function value = stage8_type1_quantile(samples, probability)
%STAGE8_TYPE1_QUANTILE Return the frozen inverse empirical CDF quantile.

samples = samples(:);
if isempty(samples) || any(~isfinite(samples)) || ...
        ~(isscalar(probability) && probability > 0 && probability < 1)
    error('stage8_type1_quantile:Inputs', ...
        'samples must be finite and probability must lie in (0,1).');
end
samples = sort(samples, 'ascend');
index = max(1, min(numel(samples), ceil(probability * numel(samples))));
value = samples(index);
end
