function [enumeration, complexity] = enumerate_exact_subset_design(context)
%ENUMERATE_EXACT_SUBSET_DESIGN Evaluate every registered rectangle.

family = context.plan.subset_family;
rows = cell(height(family), 1);
start_tic = tic;
for subset_index = 1:height(family)
    [rows{subset_index}, ~] = evaluate_stage7_subset( ...
        family(subset_index, :), context, struct('return_detail', false));
    if mod(subset_index, 100) == 0 || subset_index == height(family)
        fprintf('Stage7 exact enumeration: %d/%d subsets\n', ...
            subset_index, height(family));
    end
end
enumeration = struct2table(vertcat(rows{:}));
runtime = toc(start_tic);
if height(enumeration) ~= 961 || ...
        numel(unique(enumeration.subset_id)) ~= 961
    error('enumerate_exact_subset_design:Count', ...
        'Exact enumeration did not evaluate all 961 subsets.');
end
complexity = struct();
complexity.evaluated_subset_count = height(enumeration);
complexity.FIM_evaluations = sum(enumeration.fim_evaluation_count);
complexity.covariance_decompositions = ...
    sum(enumeration.covariance_decomposition_count);
complexity.whitener_eigendecompositions = ...
    sum(enumeration.whitener_eigendecomposition_count);
complexity.generalized_eigenvalue_evaluations = ...
    sum(enumeration.generalized_eigenvalue_evaluation_count);
complexity.runtime_sec = runtime;
end
