function tests = run_stage7_unit_tests(context, step_dir, package_dir)
%RUN_STAGE7_UNIT_TESTS Public entry for the private registered test runner.

tests = run_stage7_registered_unit_tests(context, step_dir, package_dir);
end
