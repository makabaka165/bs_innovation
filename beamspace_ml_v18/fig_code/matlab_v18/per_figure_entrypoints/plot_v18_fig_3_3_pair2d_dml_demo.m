% v18 Figure 3-3 MATLAB plotting entrypoint.

thisDir = fileparts(mfilename('fullpath'));
scriptPath = fullfile(thisDir, '..', 'single_figure_scripts', ...
    'run_generate_pair2d_parameterization_demo.m');
run(scriptPath);

