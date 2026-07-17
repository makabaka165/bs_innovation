function outputs = write_stage5_results_bundle(result_dir, cfg, evidence, ...
    tests, analyzer_count, frozen_context, overall_pass)
%WRITE_STAGE5_RESULTS_BUNDLE Expose the test-private result writer to runner.

outputs = write_stage5_results(result_dir, cfg, evidence, tests, ...
    analyzer_count, frozen_context, overall_pass);
end
