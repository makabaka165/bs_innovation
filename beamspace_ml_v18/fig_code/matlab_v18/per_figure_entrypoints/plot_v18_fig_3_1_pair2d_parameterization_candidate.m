% v18 Figure 3-1 MATLAB candidate.
% The v18 final image appears post-processed/replaced, but this is the
% current-project MATLAB candidate source located in the chapter-6 redraw script.

thisDir = fileparts(mfilename('fullpath'));
codeDir = fullfile(thisDir, '..', 'chapter6_result_redraw');
addpath(codeDir);
v08_redraw_result_figures_matlab_default('pair2d');

