% v18 Figure 5-2 MATLAB plotting entrypoint.

thisDir = fileparts(mfilename('fullpath'));
scriptPath = fullfile(thisDir, '..', 'single_figure_scripts', ...
    'run_generate_c05_adaptive_budget_mechanism_demo.m');
run(scriptPath);

