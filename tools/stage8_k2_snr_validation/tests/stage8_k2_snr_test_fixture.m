function fixture = stage8_k2_snr_test_fixture(context)
%STAGE8_K2_SNR_TEST_FIXTURE Cache deterministic non-fit test material.

persistent cached cached_hash
if ~isempty(cached) && strcmp(cached_hash, context.context_hash)
    fixture = cached;
    return;
end
trials = cell(context.constants.trial_count, 1);
metrics = cell(context.constants.trial_count, 1);
for index = 1:height(context.original_registry)
    trials{index} = stage8_k2_snr_rebuild_original_trial( ...
        context.original_registry(index, :), context);
    metrics{index} = stage8_k2_snr_compute_metrics(trials{index});
end
white_registry = stage8_k2_snr_build_white_control_registry(context);
cached = struct('original_trials', {trials}, ...
    'original_metrics', {metrics}, 'white_registry', white_registry);
cached_hash = context.context_hash;
fixture = cached;
end
