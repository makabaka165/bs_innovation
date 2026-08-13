# Stage8 K2 Classical Baseline Comparison

Protocol: `STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_V1`

Execution HEAD: `6bee94ad43d49492cb16353ec5d2b6878c645cb2`

Runtime root: `E:/bs_innovation_runtime/stage8_k2_classical_baselines_v1`

Trial reconstruction: `72/72` exact element hashes.

Integrity: counts `1`; hashes `1`; truth isolation `1`; coarse enumeration `1`; MUSIC applicability `1`; element subset `1`.

Status: `STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_COMPLETE`.

The historical conclusion `STAGE8_K2_TANGENT_PROFILE_RETAIN` is unchanged.

## Fair-set accuracy

| Set | Method | Applicable | Valid | Median/p90 joint RMSE deg | Median/p90 center deg | Median/p90 axis deg | Median/p90 rho error deg | Median/p90 vector error deg |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| ALL_72 | CORE_LITE | 72 | 72 | 0.18381185099009095 / 0.37919229496972062 | 0.11180339887498869 / 0.3334919535641554 | 18.43494882292212 / 45.000000000000121 | 0.20000000000000107 / 0.43245553203367593 | 0.20931697687897216 / 0.44721359549995793 |
| ALL_72 | CORE_PLUS | 72 | 72 | 0.14962699647489097 / 0.37617628510775392 | 0.10000000000000098 / 0.28604297589165101 | 2.6938476699931604 / 45.000000000000121 | 0.18996142804054236 / 0.43654308352130305 | 0.2061552812808834 / 0.44721359549995793 |
| ALL_72 | TANGENT_PROFILE_SAFE | 72 | 72 | 0.077518689009694899 / 0.25282012017906685 | 0.029895612122433704 / 0.1134588660299149 | 6.0771458852455957 / 26.529970324425665 | 0.10760918996880112 / 0.30507622190136024 | 0.12421429606116124 / 0.3482861119204595 |
| ALL_72 | FULL4D_BEAMSPACE_CML_MULTISTART | 72 | 72 | 0.13586974010695929 / 0.33685151025910787 | 0.096724349541444432 / 0.26547024586093548 | 4.8445546112408273 / 27.726397936304121 | 0.13590745286580408 / 0.42289463433506663 | 0.14706852021550521 / 0.43279582527351756 |
| ELEMENT_REFERENCE_24 | TANGENT_PROFILE_SAFE | 24 | 24 | 0.076509167067210213 / 0.32592160697847611 | 0.036300850882086316 / 0.10984882603363097 | 4.0704128154975656 / 24.30528283562705 | 0.10280257811320313 / 0.21812389335653584 | 0.10788993456303723 / 0.22819026892459487 |
| ELEMENT_REFERENCE_24 | FULL4D_BEAMSPACE_CML_MULTISTART | 24 | 24 | 0.1635201169330098 / 0.36568499695807338 | 0.10166193006915311 / 0.31703701742361945 | 4.618003948755212 / 23.771949174568704 | 0.15828889244729161 / 0.32393113530906115 | 0.16323946681170981 / 0.33936391142127287 |
| ELEMENT_REFERENCE_24 | FULL4D_ELEMENT_CML_MULTISTART | 24 | 24 | 0.164849075164194 / 0.33941253223877815 | 0.096325079718177525 / 0.30876671117944615 | 4.6934785753260932 / 23.731251563725937 | 0.15873488975694527 / 0.40339780344332715 | 0.1636693116742842 / 0.41123110171183919 |
| MUSIC_APPLICABLE_48 | TANGENT_PROFILE_SAFE | 48 | 48 | 0.075522316196436026 / 0.12915199612389025 | 0.026091474380962799 / 0.1000000000000008 | 3.8279024123185108 / 17.17685787362382 | 0.10760918996880112 / 0.19929999999999967 | 0.11641546019248804 / 0.1993296531219598 |
| MUSIC_APPLICABLE_48 | FULL4D_BEAMSPACE_CML_MULTISTART | 48 | 48 | 0.11299817467958656 / 0.28550370223724708 | 0.093534289347897162 / 0.2611812968660841 | 2.9839880808187753 / 19.471794450209394 | 0.12616953912993831 / 0.29370039949185694 | 0.12928711938240289 / 0.29484856252514097 |
| MUSIC_APPLICABLE_48 | BEAMSPACE_MUSIC_K2 | 48 | 0 | NaN / NaN | NaN / NaN | NaN / NaN | NaN / NaN | NaN / NaN |
| MUSIC_APPLICABLE_48 | ELEMENT_MUSIC_K2 | 48 | 0 | NaN / NaN | NaN / NaN | NaN / NaN | NaN / NaN | NaN / NaN |

## Paired joint-RMSE counts

| Set | Comparison | Pairs | Wins | Ties | Losses |
|---|---|---:|---:|---:|---:|
| ALL_72 | TANGENT_PROFILE_SAFE_vs_FULL4D_BEAMSPACE_CML_MULTISTART | 72 | 56 | 0 | 16 |
| ELEMENT_REFERENCE_24 | TANGENT_PROFILE_SAFE_vs_FULL4D_BEAMSPACE_CML_MULTISTART | 24 | 21 | 0 | 3 |
| ELEMENT_REFERENCE_24 | TANGENT_PROFILE_SAFE_vs_FULL4D_ELEMENT_CML_MULTISTART | 24 | 19 | 0 | 5 |
| ELEMENT_REFERENCE_24 | FULL4D_BEAMSPACE_CML_MULTISTART_vs_FULL4D_ELEMENT_CML_MULTISTART | 24 | 10 | 0 | 14 |
| MUSIC_APPLICABLE_48 | TANGENT_PROFILE_SAFE_vs_FULL4D_BEAMSPACE_CML_MULTISTART | 48 | 42 | 0 | 6 |
| MUSIC_APPLICABLE_48 | TANGENT_PROFILE_SAFE_vs_BEAMSPACE_MUSIC_K2 | 0 | 0 | 0 | 0 |
| MUSIC_APPLICABLE_48 | TANGENT_PROFILE_SAFE_vs_ELEMENT_MUSIC_K2 | 0 | 0 | 0 | 0 |
| MUSIC_APPLICABLE_48 | FULL4D_BEAMSPACE_CML_MULTISTART_vs_BEAMSPACE_MUSIC_K2 | 0 | 0 | 0 | 0 |

Tie tolerance is reporting-only at `1e-6 deg`.

## Numerical-scope audit

- Beamspace full4D CML returned finite rank-two fits for `72/72`: 14 converged, 4 stationary, and 54 finite max-sweep-valid outputs.
- Element full4D CML returned finite rank-two fits for `24/24`: 4 converged and 20 finite max-sweep-valid outputs.
- Beamspace full4D likelihood was below the frozen raw Tangent likelihood in `10/72` trials. These rows remain valid numerical baseline outputs but are marked `NUMERICAL_OPTIMIZATION_INCOMPLETE`, exactly as preregistered; the budget was not retuned.
- The 10 flags span all profiles (P1/P2/P3/P4 counts `3/3/2/2`) and both noise models. They do not explain the overall Tangent advantage.
- On the 62 beamspace trials without that flag, Tangent still wins/ties/loses `49/0/13`; median/p90 joint RMSE is `0.083189862 / 0.263513058 deg` for Tangent and `0.154032766 / 0.339886295 deg` for full4D CML.

The full4D outputs are finite deterministic multistart approximations, not global-optimum proofs. The frequent max-sweep-valid status and the 10 explicit likelihood shortfalls limit any claim about the theoretical CML optimum.

## Complexity

| Method | Applicable | Mean score calls | Mean SVD calls | Mean eig calls | Median/p90 runtime sec |
|---|---:|---:|---:|---:|---:|
| TANGENT_PROFILE_SAFE | 72 | 394.236111 | 861.194444 | 0 | 4.953134 / 5.355303 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 72 | 4548.708333 | 9097.416667 | 0 | 5.480052 / 7.476542 |
| FULL4D_ELEMENT_CML_MULTISTART | 24 | 4478.500000 | 4478.500000 | 0 | 14.713124 / 96.611377 |
| BEAMSPACE_MUSIC_K2 | 48 | 19521 | 0 | 1 | 0.454142 / 0.673814 |
| ELEMENT_MUSIC_K2 | 48 | 19521 | 0 | 1 | 6.336423 / 6.681202 |

Tangent uses about `11.54x` fewer score calls and `10.56x` fewer SVD calls than beamspace full4D CML. MATLAB wall-clock runtime is only modestly lower because the current Tangent implementation has higher per-call overhead; the supported efficiency statement is about registered calls, not a large wall-clock speedup.

## MUSIC result

- `L=1`: `24/24` rows per MUSIC method are `NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK`; these are not failures and are excluded from comparisons.
- `L in {4,8}`: `48/48` rows per method are applicable. Sample ranks are exactly 4 at `L=4` and 8 at `L=8`; no applicable row is signal-subspace-rank deficient.
- Every applicable beamspace spectrum and every applicable element spectrum has exactly one 8-neighbor local maximum on the registered 19,521-point grid. Consequently both methods have `0/48` valid two-peak outputs and status `MUSIC_FEWER_THAN_TWO_PEAKS` for all applicable trials.
- No MUSIC RMSE or paired wins/losses are reported because no two-angle estimate exists under the preregistered peak rule. This is not converted into a Tangent win and is not a resolved/unresolved decision.

Thus standard unsmoothed MUSIC, although algebraically applicable on the multi-snapshot subset, does not furnish a two-peak K2 estimate in these registered close-source domains. No spatial smoothing, forward/backward smoothing, root-MUSIC, or truth-based peak separation was introduced.

## P2/P4 evidence

All-72 profile medians compare Tangent with the less constrained beamspace fit:

| Profile | Method | N | Joint RMSE | Center | Axis | Rho error | Vector error |
|---|---|---:|---:|---:|---:|---:|---:|
| P2 | TANGENT_PROFILE_SAFE | 18 | 0.113812 | 0.078223 | 4.292103 | 0.199000 | 0.199004 |
| P2 | FULL4D_BEAMSPACE_CML_MULTISTART | 18 | 0.212496 | 0.129311 | 2.868324 | 0.187689 | 0.187753 |
| P4 | TANGENT_PROFILE_SAFE | 18 | 0.087920 | 0.031869 | 8.780279 | 0.099000 | 0.099021 |
| P4 | FULL4D_BEAMSPACE_CML_MULTISTART | 18 | 0.175967 | 0.122634 | 11.248080 | 0.208227 | 0.208913 |

On the fair `L=4` element-reference subset:

| Profile | Method | N | Joint RMSE | Center | Axis | Rho error | Vector error |
|---|---|---:|---:|---:|---:|---:|---:|
| P2 | TANGENT_PROFILE_SAFE | 6 | 0.106113 | 0.083627 | 0.985418 | 0.163235 | 0.163408 |
| P2 | FULL4D_BEAMSPACE_CML_MULTISTART | 6 | 0.334110 | 0.307589 | 7.181488 | 0.205383 | 0.205392 |
| P2 | FULL4D_ELEMENT_CML_MULTISTART | 6 | 0.331714 | 0.301781 | 8.983895 | 0.189806 | 0.189824 |
| P4 | TANGENT_PROFILE_SAFE | 6 | 0.088822 | 0.042286 | 14.228375 | 0.099000 | 0.099007 |
| P4 | FULL4D_BEAMSPACE_CML_MULTISTART | 6 | 0.175967 | 0.124875 | 15.129278 | 0.204884 | 0.205196 |
| P4 | FULL4D_ELEMENT_CML_MULTISTART | 6 | 0.176170 | 0.135161 | 19.002970 | 0.253253 | 0.261222 |

Interpretation A is not observed: freeing center, axis, and scale does not descriptively repair P2/P4. P2 obtains only a small median rho/vector improvement at the cost of much worse center and endpoint error, while P4 is worse on all principal endpoint/scale metrics.

Interpretation B is not supported as the primary P2/P4 cause: element CML is nearly identical to beamspace CML for P2 and no better for P4. Element data do help the easier P1/P3 median joint RMSE on the reference subset (`0.047852/0.082669 deg` versus beamspace `0.075135/0.127864 deg`), so the beamspace is not information-neutral in every profile, but that gain does not recover P2/P4.

Interpretation C is the best-supported P2/P4 diagnosis: both observation domains show center/scale errors and outliers in the weak-secondary, small-separation profiles, consistent with a finite-snapshot ML threshold/statistical-ambiguity region. This is descriptive evidence, not a new threshold or pass/fail gate, and finite-multistart limitations remain an explicit caveat.

Interpretation D is also observed: Tangent's fixed geometry acts as useful system-specific regularization/dimension reduction. It retains lower endpoint error on the registered trials while using an order of magnitude fewer score/SVD calls than the less constrained beamspace search.

P2/P4 diagnosis: `PRIMARY_C_ML_THRESHOLD_STATISTICAL_AMBIGUITY_WITH_D_DIMENSION_REDUCTION_BENEFIT`.

## Alpha-rho motivation

Alpha-rho follow-up motivation: `NO`.

The preregistered condition for such motivation was interpretation A. Because full4D freedom did not repair P2/P4, this experiment does not justify implementing or tuning alpha-rho. The theoretical appendix remains `NOT_IMPLEMENTED`, `NOT_TUNED`, and `NOT_VALIDATED`.

## Boundaries

Element and beamspace likelihood values are not compared directly. MUSIC L=1 N/A rows and applicable single-peak rows are not counted as Tangent wins. No Tangent modification, alpha-rho implementation, automatic K, bootstrap, production change, expanded trial set, additional MUSIC variant, or upstream-branch merge is authorized.

No algorithm change: `true`.
