function context = prepare_stage6_context(cfg, step_dir, package_dir)
%PREPARE_STAGE6_CONTEXT Load the private locked plan and fixed models.

plan = build_stage6_locked_plan();
context = build_stage6_test_context(cfg, plan, step_dir, package_dir);
end
