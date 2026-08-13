function result = test_cylinder_kronecker_factorization(context)
%TEST_CYLINDER_KRONECKER_FACTORIZATION Verify a=b kron v at eight angles.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
constants = context.constants;
model = context.models(1).model;
rng_state = rng;
rng_cleanup = onCleanup(@() rng(rng_state));
rng(817001, 'twister');
angles = [constants.azimuth_domain_deg(1) + ...
    diff(constants.azimuth_domain_deg) * rand(8, 1), ...
    constants.elevation_domain_deg(1) + ...
    diff(constants.elevation_domain_deg) * rand(8, 1)];
manifold = build_stage8_element_manifold(angles, model);
k0 = 2 * pi / model.lambda;
z = (0:constants.N_el - 1).' * ...
    model.array_configuration.arr.dz;
phi = model.array_meta.phiAct;
residuals = zeros(8, 1);
for index = 1:8
    theta = angles(index, 2);
    vertical = exp(1j * k0 * z * sind(theta));
    azimuth = exp(1j * k0 * model.array_configuration.arr.R * ...
        cosd(theta) * cosd(angles(index, 1) - phi));
    expected = (vertical * azimuth);
    residuals(index) = norm(manifold.A(:, index) - expected(:)) / ...
        max(1, norm(expected(:)));
end
assert(max(residuals) <= constants.structure_tolerance, ...
    'test_cylinder_kronecker_factorization:Residual', ...
    'Cylinder manifold does not satisfy exact Kronecker factorization.');
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
