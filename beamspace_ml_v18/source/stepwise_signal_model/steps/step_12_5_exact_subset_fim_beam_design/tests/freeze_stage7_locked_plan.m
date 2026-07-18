function [plan, outputs] = freeze_stage7_locked_plan( ...
    cfg, repo_dir, step_dir, result_dir)
%FREEZE_STAGE7_LOCKED_PLAN Public test-layer entry to the private registry.

plan = build_stage7_locked_plan(cfg, repo_dir, step_dir);
outputs = write_stage7_plan_artifacts(plan, result_dir);
end
