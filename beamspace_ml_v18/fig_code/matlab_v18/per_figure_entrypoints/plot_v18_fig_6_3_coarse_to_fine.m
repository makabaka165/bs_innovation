% v18 Figure 6-3 MATLAB plotting entrypoint.

thisDir = fileparts(mfilename('fullpath'));
codeDir = fullfile(thisDir, '..', 'chapter6_result_redraw');
addpath(codeDir);
v08_redraw_result_figures_matlab_default('coarse_to_fine');

