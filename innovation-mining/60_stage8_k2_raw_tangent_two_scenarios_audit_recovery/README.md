# CSV logical audit recovery

The frozen verifier imports CSV boolean fields as numeric 0/1. The summarizer expects logical indices for fit_valid and applicable. The recovery verifier is a mechanical copy of the frozen verifier with its function name changed and strict schema normalization added after the two result-table reads. No assertions or tolerances were removed or changed.

The seven fields are applicable, fit_valid, elevation_valid, conditional_valid, rho_lower_bound_hit, localization_success_01bw and resolution_success. Only exact 0/1 numeric or logical values are accepted. The source CSVs are read-only.

The successful audit used MATLAB R2022b with -singleCompThread in a fresh session. It reconstructed observations and recomputed metrics from saved angles without running estimators. The formal HEAD and source hash remained unchanged, and all 560 checkpoint hashes matched before and after the audit. The adjacent JSON record and checkpoint inventory preserve the evidence; original failure/state/log evidence remains in the experiment runtime under controller/csv_logical_audit_recovery.

To repeat the audit, use an isolated checkout of the recorded formal implementation commit, the original prepared runtime and computed artifacts. Add the frozen tool paths with stage8_k2_rtc_add_paths, then add this directory and call stage8_k2_rtc_verify_csv_logical_recovery(repo,runtime). The identity assertion requires the recorded formal HEAD; the later documentation-only result commit is intentionally not a replacement formal identity.
