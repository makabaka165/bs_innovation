% v18 Figure 4-2 MATLAB plotting entrypoint.

thisDir = fileparts(mfilename('fullpath'));
scriptPath = fullfile(thisDir, '..', 'single_figure_scripts', ...
    'run_generate_w_selection_mechanism_demo.m');
run(scriptPath);

