function fixture = build_stage8_core_v2_2_test_fixture(repo_dir)
%BUILD_STAGE8_CORE_V2_2_TEST_FIXTURE One independent K1 fixture for tests.

if nargin < 1 || isempty(repo_dir)
    repo_dir = fileparts(fileparts(fileparts(fileparts(fileparts( ...
        fileparts(fileparts(mfilename('fullpath'))))))));
end
context = build_stage8_core_v2_2_validation_context(repo_dir, false);
registry = build_stage8_core_v2_2_final_registry(context.plan.local_domain);
spec = registry(registry.K == 1, :);
spec = spec(1, :);
trial = generate_stage8_core_v2_2_trial(spec, context);
fixture = struct('context', context, 'spec', spec, 'trial', trial);
end
