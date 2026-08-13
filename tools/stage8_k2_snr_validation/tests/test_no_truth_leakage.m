function result = test_no_truth_leakage(~)
%TEST_NO_TRUTH_LEAKAGE Audit the deliberately narrow fit adapter signature.

assert(nargin(@stage8_k2_snr_fit_methods) == 3, ...
    'test_no_truth_leakage:Signature', ...
    'The fit adapter must accept only data, model, and frozen TP context.');
source = lower(fileread(which('stage8_k2_snr_fit_methods')));
for forbidden = ["truth", "profile_id", "projected", "expected_gain"]
    assert(~contains(source, forbidden), ...
        'test_no_truth_leakage:ForbiddenInput', ...
        'The fit adapter contains forbidden analysis input: %s', forbidden);
end
result = struct('pass', true, 'adapter_nargin', 3);
end
