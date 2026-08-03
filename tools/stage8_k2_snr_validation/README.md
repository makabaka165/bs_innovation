# Stage8 K2 SNR Validation

This isolated MATLAB R2022b tool implements
`STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V2`.

V1 stopped at T4 because its `1e-10` whitening residual tolerance was stricter
than the frozen double-precision whitener's measured numerical quality. V2
fixes only that registered quality gate at `1e-8`. The whitener and all SNR
formulas remain unchanged.

It performs three tasks without modifying the frozen Tangent implementation:

- reconstruct and audit all 72 evidence-31 element-SNR-controlled trials;
- create 72 paired trials controlled by expected whitened sequential-beamspace
  SNR at `-6/0/+6 dB`;
- evaluate only Core-Lite, Core-Plus, and `TANGENT_PROFILE_SAFE` on the paired
  trials and write the registered evidence bundle.

The expected and realized SNR definitions remain separate. Signal scaling never
uses a realized noise matrix. The K2 projected metric is truth-only and is
computed outside every fitting path.

Run the registered tests from the repository root with:

```matlab
addpath('tools/stage8_k2_snr_validation/matlab');
stage8_k2_snr_run_tests('E:\bs_innovation');
```

The formal run requires a clean, pushed `experiment/stage8-k2-tangent` branch,
MATLAB R2022b, and `-singleCompThread`:

```matlab
addpath('tools/stage8_k2_snr_validation/matlab');
stage8_k2_snr_run('E:\bs_innovation');
```

Formal runtime is fixed at
`E:\bs_innovation_runtime\stage8_k2_snr_domain_validation_v2`. Existing
runtime content is never resumed or overwritten.
