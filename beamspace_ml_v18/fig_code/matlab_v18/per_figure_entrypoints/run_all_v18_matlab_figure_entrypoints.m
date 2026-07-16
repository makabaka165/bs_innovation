% Run all v18 MATLAB figure plotting entrypoints collected in this folder.
% Each path is resolved independently because the underlying single-figure
% scripts clear their caller workspace.

run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_3_1_pair2d_parameterization_candidate.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_3_3_pair2d_dml_demo.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_4_2_w_selection_mechanism.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_5_2_c05_adaptive_budget_mechanism.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_6_1_model_comparison.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_6_2_w_selection_budget.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_6_3_coarse_to_fine.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_6_4_c05_policy.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_6_5_cache_runtime.m'));
run(fullfile(fileparts(mfilename('fullpath')), 'plot_v18_fig_6_6_case_boundary.m'));
