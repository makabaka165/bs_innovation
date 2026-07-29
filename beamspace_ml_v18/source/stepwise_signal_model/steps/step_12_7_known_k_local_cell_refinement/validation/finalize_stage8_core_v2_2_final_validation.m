function output = finalize_stage8_core_v2_2_final_validation(repo_dir, runtime_root)
%FINALIZE_STAGE8_CORE_V2_2_FINAL_VALIDATION Write immutable final evidence.

if isfile(fullfile(runtime_root, 'pause.request'))
    error('finalize_stage8_core_v2_2_final_validation:Pause', ...
        'Finalize is unavailable while a pause is requested.');
end
targets = { ...
    fullfile(repo_dir, 'innovation-mining', ...
    '28_stage8_core_v2_2_final_single_cpi_known_k_validation.md'), ...
    fullfile(repo_dir, 'innovation-mining', ...
    '28_stage8_core_v2_2_final_single_cpi_known_k_trials.csv'), ...
    fullfile(repo_dir, 'innovation-mining', ...
    '28_stage8_core_v2_2_final_single_cpi_known_k_summary.csv'), ...
    fullfile(repo_dir, 'innovation-mining', ...
    '28_stage8_core_v2_2_final_single_cpi_known_k_q_analysis.csv'), ...
    fullfile(repo_dir, 'innovation-mining', ...
    '28_stage8_core_v2_2_final_single_cpi_known_k_complexity.csv')};
for index = 1:numel(targets)
    if isfile(targets{index})
        error('finalize_stage8_core_v2_2_final_validation:Overwrite', ...
            'Finalize refuses to overwrite %s.', targets{index});
    end
end
summary = summarize_stage8_core_v2_2_final_validation(runtime_root);
writetable(summary.trials, targets{2});
writetable(summary.summary, targets{3});
writetable(summary.q_analysis, targets{4});
writetable(summary.complexity, targets{5});
write_report_local(targets{1}, summary);
save(fullfile(runtime_root, 'finalized.mat'), 'summary', '-mat');
output = struct('report_path', targets{1}, 'trials_path', targets{2}, ...
    'summary_path', targets{3}, 'q_analysis_path', targets{4}, ...
    'complexity_path', targets{5}, 'decision', summary.decision);
end

function write_report_local(path_now, output)
fid = fopen(path_now, 'w', 'n', 'UTF-8');
if fid < 0
    error('finalize_stage8_core_v2_2_final_validation:Write', ...
        'Cannot write final report.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Stage8 Core-V2.2 Final Single-CPI Known-K Validation\n\n');
fprintf(fid, 'SINGLE_CPI\nSINGLE_RANGE_DOPPLER_CELL\n');
fprintf(fid, 'KNOWN_K_CONDITIONAL_ESTIMATION\nNO_TRACKING_INPUT\n');
fprintf(fid, 'NO_CROSS_CPI_INPUT\nNO_MODEL_ORDER_CLAIM\n');
fprintf(fid, 'NO_FORMAL_STAGE8_1_PASS\nNO_STAGE8_2_AUTHORIZATION\n\n');
fprintf(fid, 'Final state: `%s`\n\n', output.decision.final_state);
fprintf(fid, 'Registry: K1 72/72, K2 72/72, rows 288/288.\n\n');
fprintf(fid, 'Model-order: DEFERRED\n');
fprintf(fid, 'Formal 6000-trial: DEFERRED_NOT_FAILED\n');
fprintf(fid, 'Stage8.2: NOT_EXECUTED\n');
clear cleanup
end
