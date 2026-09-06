# Two-Scenario L8 Branch Execution

Protocol: STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_V1.

Source parent: experiment/stage8-k2-raw-tangent-core-native-snr-v1 at f1b13422a91540073ecf417c3b25f5cac552b9d6.
Branch: experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1.
Worktree: E:/bs_innovation_worktrees/raw-tangent-two-scenarios-l8.
Runtime: E:/bs_innovation_runtime/experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1.

SC_A/SC_B, L=8, seven SNR values, 20 replicates: 280 scenarios, 40 bases, 560 checkpoints, 1400 rows. Five retained methods are specified in the protocol. The deletion TSV is a pre-deletion plan; every path remains at the exact parent commit. Shared scientific kernels and the ten named RTC scientific files must retain parent bytes.

Commit A records this design and deletion plan. Commit B records configuration, dispatch, output, controller adaptations, actual deletions and four preflight groups. After B is pushed, the code identity is frozen before fresh observations are fitted. Commit C is produced only after the independent audit passes. The controller completes computation, audit, result push, prompt archival and task removal. No merge/rebase/force-push or additional experiments are authorized.

Status: DESIGN_REGISTERED; NEXT=IMPLEMENTATION_AND_PREFLIGHT.
