function result = test_vertical_shift_invariance(context)
%TEST_VERTICAL_SHIFT_INVARIANCE Verify the registered positive phase shift.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
constants = context.constants;
model = context.models(1).model;
angles = [linspace(7.43, 8.57, 8).', linspace(9.81, 10.19, 8).'];
manifold = build_stage8_element_manifold(angles, model);
k0_dz = 2 * pi / model.lambda * ...
    model.array_configuration.arr.dz;
residuals = zeros(8, 1);
for index = 1:8
    matrix = reshape(manifold.A(:, index), ...
        constants.N_el, constants.N_az);
    expected = exp(1j * k0_dz * sind(angles(index, 2))) * ...
        matrix(1:end-1, :);
    residuals(index) = norm(matrix(2:end, :) - expected, 'fro') / ...
        max(1, norm(expected, 'fro'));
end
assert(max(residuals) <= constants.structure_tolerance, ...
    'test_vertical_shift_invariance:Residual', ...
    'Vertical steering does not satisfy the positive-phase shift.');
result = struct('pass', true, 'max_residual', max(residuals));
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
