function context = prepare_stage6_context(cfg, step_dir, package_dir, repo_dir)
%PREPARE_STAGE6_CONTEXT Load the private locked plan and fixed models.

if nargin < 4 || isempty(repo_dir)
    repo_dir = fileparts(package_dir);
end
plan = build_stage6_locked_plan(repo_dir);
context = build_stage6_test_context(cfg, plan, step_dir, package_dir);
end
