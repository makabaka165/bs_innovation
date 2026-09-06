# Two-Scenario L8 Implementation Record

Source parent: f1b13422a91540073ecf417c3b25f5cac552b9d6.
Design commit: e1372cc.

The registry now derives 280 scenarios, 40 bases, 560 checkpoints, 1400 rows and 14 representative traces from SC_A/SC_B, L=8, seven SNR values and 20 replicates. Scenario IDs use RTC2L8. Both geometry rows are [8,10,0.45,30]; source conditions are [0,0] and [-3,0.7]. Source phase and seed generators are unchanged.

The Element wrapper mechanically extracts the parent's Root case and returns two fits. All retained methods are applicable. Root elevation/conditional diagnostics are exported separately. Element MUSIC resources, retired dispatch and 93 manifest-listed old files are removed. Retained baseline default-constant files lose obsolete experiment metadata, while every scientific budget is retained. The generic shared MUSIC kernel still contains its dormant Element branch.

Scope compares all 19 named RTC/baseline scientific files against parent Git blob bytes; physical/manifold/DML changes are outside the allowed paths. Windows core.autocrlf affects checkout line endings only. No scientific core, tolerance, optimizer budget, SNR formula or success criterion is changed.

Current data and plots use a single 60_stage8_k2_raw_tangent_two_scenarios_ prefix. Summary tables include success counts, valid counts, lower-bound hits and Root failure stages. Pairing is strictly within a domain and identical observation hashes, with 1e-6 deg RMSE ties and common-valid counts. Eight figures are split by scenario and use only exported CSV/MAT.

The controller retains the parent launcher/engine and UTC identity logic. One actual launch test passed on PowerShell 5.1 and 7 with one compute worker. The isolated scheduler contract test removes its own task. Formal execution uses the new 15-minute task and mutex. Exceptions save a process snapshot. Git failures retry closeout, reusing an already-created result commit. Final closeout refreshes the report hash after audit status changes, archives execution authority and removes only the new task.

Preflight retains the parent's 18 checks in four groups. The original SNR fluctuation check sampled replicate 1, which meant 12 bases in the parent but only two here. Its two-sample spread assertion failed during development. The adapted check covers all 40 registered bases without fitting any additional scenario; the original 0.01 dB spread assertion, 1e-12 dB nominal-SNR limit and original scaling tolerances remain unchanged. The first failed log is preserved in the new runtime. The passing/current preflight JSON is the authoritative gate record.

Smoke observations/checkpoints are written only to runtime/tests/smoke and never reused for formal checkpoints. Science is frozen only after the implementation commit is pushed. Performance outcomes do not determine preflight or audit validity.

NEXT: freeze the pushed implementation identity, execute the registered experiment, independently audit, and close out for USER_REVIEW. MERGE_BACK=NOT_AUTHORIZED.
