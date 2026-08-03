# Stage8 K2 White-SNR Monte Carlo

This isolated tool executes the registered 1680-trial, single-process
white-SNR Monte Carlo closure for the frozen Stage8 K2 estimators.

Protocol:
`STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_AND_CLOSURE_V1`

The tool reuses the frozen Stage8 K2 SNR-domain construction and fit paths.
It does not modify Tangent, Core-Lite, Core-Plus, the measurement model,
whitening, source/noise models, or SNR definitions.

Run tests with one MATLAB R2022b thread:

```matlab
addpath('E:\bs_innovation\tools\stage8_k2_white_snr_monte_carlo\matlab');
stage8_k2_mc_run_tests('E:\bs_innovation');
```

Start or resume the formal run:

```matlab
addpath('E:\bs_innovation\tools\stage8_k2_white_snr_monte_carlo\matlab');
out = stage8_k2_mc_run( ...
    'E:\bs_innovation', ...
    'E:\bs_innovation_runtime\stage8_k2_white_snr_monte_carlo_v1');
disp(out.status);
```

The runner requires MATLAB R2022b with `-singleCompThread`, a clean pushed
Tangent branch, and no parallel pool. It validates and skips immutable
checkpoints on resume. A stale `.tmp` is ignored and replaced only when its
missing trial is rerun; an invalid final checkpoint stops execution.

No production selector or online SNR threshold is created.
