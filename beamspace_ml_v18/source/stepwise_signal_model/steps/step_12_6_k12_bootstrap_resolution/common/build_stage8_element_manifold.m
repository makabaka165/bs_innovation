function manifold = build_stage8_element_manifold(target_angles_deg, model)
%BUILD_STAGE8_ELEMENT_MANIFOLD Reuse the frozen factor-1 element API.

required = {'W_I','array_meta','array_configuration','lambda', ...
    'phase_factor','element_order'};
if ~(isstruct(model) && isscalar(model) && all(isfield(model, required)) && ...
        model.phase_factor == 1)
    error('build_stage8_element_manifold:Model', ...
        'model must expose the frozen factor-1 element configuration.');
end
pool = struct('W0', complex(zeros(size(model.W_I, 1), 0)), ...
    'array_meta', model.array_meta);
manifold = build_stage7_element_manifold( ...
    target_angles_deg, pool, model.array_configuration);
if size(manifold.A, 1) ~= size(model.W_I, 1)
    error('build_stage8_element_manifold:ElementOrder', ...
        'The Stage7 manifold and Stage8 measurement rows disagree.');
end
manifold.element_order = model.element_order;
end
