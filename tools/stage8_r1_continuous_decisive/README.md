# Stage8 R1 continuous refinement decisive experiment

This external prototype implements the authorized 24-trial algorithm-choice
experiment. It leaves frozen Stage8 code, calibration, threshold artifacts,
formal results, and the compact diagnostic untouched.

Run powershell/Stage8R1Decisive.ps1 in this order:

1. -Action Init
2. -Action Gates
3. -Action Start
4. -Action Status
5. -Action Finalize after all 24 checkpoints are complete

The runner uses MATLAB R2022b with -singleCompThread, never starts a pool,
and records checkpoint data outside the repository. Finalize alone writes
the four authorized innovation-mining/24_* output files.
