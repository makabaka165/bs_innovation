function result = test_applicability_contract(context)
%TEST_APPLICABILITY_CONTRACT Verify P2 and colored-noise structural N/A.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
registry = context.registry;
counts = zeros(numel(context.constants.method_ids), 1);
for method_index = 1:numel(context.constants.method_ids)
    method_id = context.constants.method_ids(method_index);
    for trial_index = 1:height(registry)
        rule = stage8_k2_sb_applicability( ...
            registry(trial_index, :), method_id);
        counts(method_index) = counts(method_index) + rule.applicable;
        if registry.profile_id(trial_index) == "P2"
            assert(~rule.applicable && rule.status == ...
                "NOT_APPLICABLE_EQUAL_ELEVATION_MULTIPLICITY");
        elseif method_id ~= ...
                "ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML" && ...
                registry.noise_profile_id(trial_index) ~= "WHITE"
            assert(~rule.applicable && contains(rule.status, ...
                "NOT_APPLICABLE_COLORED_NOISE_STANDARD"));
        end
    end
end
assert(isequal(counts, [54; 27; 27]), ...
    'test_applicability_contract:Counts', ...
    'Registered method applicability counts are incorrect.');
result = struct('pass', true, 'applicable_counts', counts);
end

function [context, cleanup] = context_local(context)
cleanup = [];
if nargin < 1 || isempty(context)
    test_dir = fileparts(mfilename('fullpath'));
    repo_dir = fileparts(fileparts(fileparts(test_dir)));
    cleanup = stage8_k2_sb_add_paths(repo_dir);
    context = stage8_k2_sb_build_context(repo_dir);
end
end
