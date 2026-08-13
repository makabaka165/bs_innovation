# Stage8 K2 Tangent-Profile Diagnostic Correction

Authorization: `AUTHORIZE_STAGE8_K2_TP1_AXIS_DIAGNOSTIC_AND_EVIDENCE_CORRECTION_V1`

Status: `STAGE8_K2_TP1_DIAGNOSTIC_CORRECTION_PASS`

Original final decision: `STAGE8_K2_TANGENT_PROFILE_RETAIN`

- Decision changed: `false`
- Fitting rerun: `false`
- Angles/RSS/loglik/RMSE changed: `false`
- Correction scope: diagnostic orientation and evidence completeness only.

## Runtime evidence

| File | Bytes | SHA-256 |
|---|---:|---|
| `E:\bs_innovation_runtime\stage8_k2_tangent_profile_v1\tangent_diagnostics.csv` | 35356 | `406091f4392fa658c4ff16b2361e672b567dd16bd33f87990d003e88e165a496` |
| `E:\bs_innovation_runtime\stage8_k2_tangent_profile_v1\method_rows.csv` | 83982 | `68ead277ce3e0a38e7be3fdb3a43b358a53424f59aefb4560707dfc100ac7cba` |
| `E:\bs_innovation_runtime\stage8_k2_tangent_profile_v1\registry.csv` | 13065 | `54b381647ac17273d1a6b2d046bdfcd2a88595d3b88729b582a71b4332312f41` |
| `E:\bs_innovation_runtime\stage8_k2_tangent_profile_v1\complete_run.mat` | 41556 | `8234f3256fcf1e037a540f3fa122b043e3ff1b23f2c45d68fcc6742883628de9` |

Runtime rows: diagnostics `72`, methods `216`, registry `72`.

## Axis correction

- Original oriented median/p90: `7.7820411806905145 / 166.43295447715022 deg`.
- Corrected axis median/p90: `6.5718819967584521 / 27.970318945949636 deg`.
- Oriented errors above 90 deg mapped to the same axis: `13/72`.
- Original 166-180 deg tail count: `8/72`.

The endpoint set is unchanged by `u -> -u`; the formal direction diagnostic is therefore `acosd(abs(dot(u_hat,u_true)))` in `[0,90]` degrees.

## Overall separation diagnostics

- Rho error median/p90: `0.10684032544332001 / 0.22774932519295715 deg`.
- Relative rho error median/p90: `0.9378324924679835 / 1.4475779000775408`.
- Selected separation median: `0.21045768631633807 deg`.
- Selected-separation error median/p90: `0.10760918996880155 / 0.30507622190136019 deg`.
- Separation-vector error median/p90: `0.12421429606116149 / 0.34828611192045961 deg`.
- Joint angle RMSE median: `0.077518689009694899 deg`.
- Raw rho lower-bound hits: `23`.

## Gamma quartiles

| Scope | N | Gamma median | Axis direction median/p90 deg | Rho error median/p90 deg | Relative rho median/p90 | Selected-separation error median/p90 deg | Separation-vector median/p90 deg | Joint RMSE median deg | Raw valid | Fallback | Lower hits | Upgrade/fallback |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Q1 | 18 | 3.8049956565289698 | 20.352265797908476 / 62.855795568486052 | 0.1177802070952659 / 0.26083023614188117 | 0.98999999999999999 / 1.9623927756154043 | 0.16592135623731008 / 0.33688295107356003 | 0.19056060658799351 / 0.39228274344846309 | 0.10050354884677075 | 1 | 0.22222222222222221 | 7 | 14 / 4 |
| Q2 | 18 | 32.368613124289702 | 8.4038764915002133 / 18.518494028943191 | 0.094595530628773655 / 0.18527497554023031 | 0.6060302213342692 / 0.99383333333333335 | 0.098435043696714894 / 0.29563307652783916 | 0.098496408392898152 / 0.30903528060673069 | 0.063073345111808399 | 1 | 0.16666666666666666 | 5 | 15 / 3 |
| Q3 | 18 | 95.984739955475391 | 4.2296124135762394 / 14.743717542720979 | 0.116197989121443 / 0.32462825607851309 | 0.90917697655172103 / 1.9238983637513927 | 0.11619798912144369 / 0.3390366596101031 | 0.12421429606116149 / 0.34346952450679902 | 0.075396604340103146 | 1 | 0.1111111111111111 | 6 | 16 / 2 |
| Q4 | 18 | 742.89846322690005 | 1.0535885257913356 / 6.0531798742231535 | 0.13665495475807149 / 0.19900000000000001 | 0.69168674790938489 / 0.995 | 0.081482907953387071 / 0.19899999999999821 | 0.081579529941532947 / 0.1990022285078886 | 0.089277896222128506 | 0.88888888888888884 | 0.22222222222222221 | 5 | 14 / 4 |

## Profile summaries

| Scope | N | Gamma median | Axis direction median/p90 deg | Rho error median/p90 deg | Relative rho median/p90 | Selected-separation error median/p90 deg | Separation-vector median/p90 deg | Joint RMSE median deg | Raw valid | Fallback | Lower hits | Upgrade/fallback |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| P1 | 18 | 166.3331453737425 | 2.7892328657205594 / 21.012812609002072 | 0.063965815906773305 / 0.26628305955018383 | 0.21321938635591009 / 0.88761019850061285 | 0.081804977617524949 / 0.2756797974644658 | 0.0864088623604575 / 0.27568213140309944 | 0.052124630845713296 | 0.94444444444444442 | 0.16666666666666666 | 2 | 15 / 3 |
| P2 | 18 | 101.86746265741249 | 6.2310150414551835 / 21.412146712268704 | 0.19900000000000001 / 0.31783505578524557 | 0.995 / 1.5891752789262277 | 0.19899999999999821 / 0.47393178660199331 | 0.19900350247937498 / 0.49873610062478391 | 0.11381225617749299 | 1 | 0.33333333333333331 | 8 | 12 / 6 |
| P3 | 18 | 31.56869446989705 | 6.0260385790772286 / 13.435237547045475 | 0.106605156226405 / 0.14899999999999999 | 0.71070104150936675 / 0.99333333333333329 | 0.098963065045260201 / 0.14900000000000149 | 0.099471222394993647 / 0.14902474966792839 | 0.058131940266647399 | 0.94444444444444442 | 0.1111111111111111 | 4 | 16 / 2 |
| P4 | 18 | 16.571109468421099 | 9.7989353730505329 / 55.240663335694194 | 0.099000000000000005 / 0.20272785952868183 | 0.98999999999999999 / 2.027278595286818 | 0.099000000000000032 / 0.24984930065698885 | 0.099020687853347611 / 0.27431871357156634 | 0.087919828420263746 | 1 | 0.1111111111111111 | 9 | 16 / 2 |

## Interpretation boundary

Tangent-Profile demonstrated a clear joint-angle RMSE improvement in the registered scenarios. Any statement about stable recovery of the true two-target separation must also use the rho, relative-rho, selected-separation, separation-vector, and lower-bound diagnostics in this addendum. No resolved/unresolved threshold or new decision gate is introduced.

The candidate has lower registered score/SVD call counts than Core-Plus, while the current MATLAB wall-clock runtime is higher. The allowed description is: accuracy-retained theory-driven candidate; lower registered score/SVD call count; current MATLAB implementation not runtime-efficient.

The original `31_*` evidence remains the byte-unchanged execution record. This `32_*` addendum changes no scientific fit or RETAIN decision. Registered `rho_min_deg` remains `0.001`.
