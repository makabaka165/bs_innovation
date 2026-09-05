# Raw Tangent Core Native-SNR Experiment

Protocol: `STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_V1`.

Branch: `experiment/stage8-k2-raw-tangent-core-native-snr-v1`.

Status: DESIGN_COMMITTED; implementation and all 18 gates pending. Legacy paths may only be removed after Commit B passes the fixed gates.

The active scientific target is `TANGENT_PROFILE_CORE`: white Beamspace K1 DML center, projected derivative direction and full two-target manifold scale search. Both native domains use IID circular complex Gaussian noise with nominal variance equal to clean signal energy divided by linear SNR and sample count. Realized noise power is unconstrained.

The registration is 1680 scenarios (7 SNR values, 3 snapshot counts, 4 profiles, 20 replicates), 240 common base realizations and 13440 method rows. Three Beamspace methods share Z; five Element methods share Y. Cross-domain comparisons are scenario-matched native-SNR references.

See [the protocol](../../innovation-mining/57_stage8_k2_raw_tangent_core_native_snr_theory_and_protocol.md) and [the pre-deletion manifest](../../innovation-mining/57_stage8_k2_raw_tangent_pruning_manifest.csv). Existing 43-48 evidence is historical Safe reference only. Production integration is not authorized.

