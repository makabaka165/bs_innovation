# Stage8 K2 SNR T4 Numeric-Quality Correction

Protocol:
`STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V2`

Authorization:
`AUTHORIZE_STAGE8_K2_SNR_T4_NUMERIC_QUALITY_CORRECTION_AND_COMPLETION_V2`

## V1 Stop Record

V1 status:
`STAGE8_K2_SNR_DOMAIN_VALIDATION_INVALID`

Failure stage:
`T4 only`

WHITE residual:
`5.7966605659e-9`

CORRELATED residual:
`3.1070711917e-9`

V1 threshold:
`1e-10`

V2 threshold:
`1e-8`

Tdiff after frozen reconstruction:
`0`

SNR formulas changed:
`false`

Tangent changed:
`false`

Whitener changed:
`false`

Phase B executed under V1:
`false`

Scientific interpretation:
`V1 gate too strict, not a whitening or SNR formulation failure`

## Correction Boundary

The registered numerical-quality residual is

```math
\delta_w=\frac{\|T_I C_I T_I^H-I_r\|_F}{\sqrt r}.
```

V2 accepts the frozen double-precision whitener only when
`delta_w <= 1e-8`. The observed maximum, `5.7966605659e-9`, remains below
that fixed gate. The corresponding first-order SNR effect is below
approximately `4.34e-8 dB`, negligible on the registered `-6/0/+6 dB`
scale.

This addendum does not permit rebuilding `T_I`, changing `C_I`, changing the
effective rank, modifying the measurement registry, or further relaxing the
tolerance. Element-SNR identity, raw-covariance identity, expected white-SNR
scaling, paired seeds, and truth-isolation tolerances remain unchanged.
