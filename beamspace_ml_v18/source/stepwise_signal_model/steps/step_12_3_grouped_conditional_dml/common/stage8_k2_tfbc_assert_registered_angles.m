function indices = stage8_k2_tfbc_assert_registered_angles( ...
    angles_deg, local_domain, caller_id)
%STAGE8_K2_TFBC_ASSERT_REGISTERED_ANGLES Enforce exact grid membership.

if nargin < 3 || isempty(caller_id), caller_id = 'FIXED_BACKBONE'; end
required = {'az_grid_deg','el_grid_deg'};
if ~(isstruct(local_domain) && isscalar(local_domain) && ...
        all(isfield(local_domain, required)))
    error('stage8_k2_tfbc_assert_registered_angles:Domain', ...
        'local_domain is incomplete.');
end
if ~(isnumeric(angles_deg) && ismatrix(angles_deg) && ...
        size(angles_deg, 2) == 2 && ~isempty(angles_deg) && ...
        all(isfinite(angles_deg(:))))
    error('stage8_k2_tfbc_assert_registered_angles:Angles', ...
        'BLOCKED_CURRENT_START_NOT_REGISTERED: %s is invalid.', caller_id);
end
az_grid = double(local_domain.az_grid_deg(:).');
el_grid = double(local_domain.el_grid_deg(:).');
az_step = regular_step_local(az_grid, 'azimuth');
el_step = regular_step_local(el_grid, 'elevation');
tolerance = 1e-11;
indices = zeros(size(angles_deg, 1), 2);
for target = 1:size(angles_deg, 1)
    az_index = 1 + round((angles_deg(target, 1) - az_grid(1)) / az_step);
    el_index = 1 + round((angles_deg(target, 2) - el_grid(1)) / el_step);
    if az_index < 1 || az_index > numel(az_grid) || ...
            el_index < 1 || el_index > numel(el_grid) || ...
            abs(angles_deg(target, 1) - az_grid(az_index)) > tolerance || ...
            abs(angles_deg(target, 2) - el_grid(el_index)) > tolerance
        error('stage8_k2_tfbc_assert_registered_angles:OffGrid', ...
            ['BLOCKED_CURRENT_START_NOT_REGISTERED: %s contains an ', ...
            'off-grid angle.'], caller_id);
    end
    indices(target, :) = [az_index, el_index];
end
end

function step = regular_step_local(grid, axis_id)
delta = diff(grid);
if isempty(delta) || any(delta <= 0) || ...
        max(abs(delta - delta(1))) > 64 * eps(max(abs(grid)))
    error('stage8_k2_tfbc_assert_registered_angles:RegularGrid', ...
        'The registered %s grid is not regular.', axis_id);
end
step = delta(1);
end
