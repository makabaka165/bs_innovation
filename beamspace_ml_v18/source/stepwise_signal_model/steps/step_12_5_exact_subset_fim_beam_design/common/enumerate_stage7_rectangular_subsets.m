function family = enumerate_stage7_rectangular_subsets(pool, cfg)
%ENUMERATE_STAGE7_RECTANGULAR_SUBSETS Enumerate all 961 physical rectangles.

B_e0 = numel(pool.elevation_beam_deg);
B_a0 = numel(pool.azimuth_beam_deg);
row_count = (2 ^ B_e0 - 1) * (2 ^ B_a0 - 1);
subset_id = strings(row_count, 1);
elevation_mask_integer = zeros(row_count, 1);
azimuth_mask_integer = zeros(row_count, 1);
I_e_global = strings(row_count, 1);
I_a_global = strings(row_count, 1);
sequential_channel_ids = strings(row_count, 1);
B_e = zeros(row_count, 1);
B_a = zeros(row_count, 1);
B_out = zeros(row_count, 1);
MAC_el = zeros(row_count, 1);
MAC_az = zeros(row_count, 1);
MAC_total = zeros(row_count, 1);
row_index = 0;
for elevation_integer = 1:(2 ^ B_e0 - 1)
    elevation_indices = find(bitget(elevation_integer, 1:B_e0));
    for azimuth_integer = 1:(2 ^ B_a0 - 1)
        azimuth_indices = find(bitget(azimuth_integer, 1:B_a0));
        row_index = row_index + 1;
        channels = reshape(elevation_indices(:) + ...
            (azimuth_indices(:).' - 1) * B_e0, 1, []);
        channels = channels(:).';
        cost = stage7_subset_cost(numel(elevation_indices), ...
            numel(azimuth_indices), cfg);
        subset_id(row_index) = sprintf('RECT_E%02d_A%02d', ...
            elevation_integer, azimuth_integer);
        elevation_mask_integer(row_index) = elevation_integer;
        azimuth_mask_integer(row_index) = azimuth_integer;
        I_e_global(row_index) = join(string(elevation_indices), ';');
        I_a_global(row_index) = join(string(azimuth_indices), ';');
        sequential_channel_ids(row_index) = join(string(channels), ';');
        B_e(row_index) = numel(elevation_indices);
        B_a(row_index) = numel(azimuth_indices);
        B_out(row_index) = cost.B_out;
        MAC_el(row_index) = cost.MAC_el;
        MAC_az(row_index) = cost.MAC_az;
        MAC_total(row_index) = cost.MAC_total;
    end
end
family = table(subset_id, elevation_mask_integer, azimuth_mask_integer, ...
    I_e_global, I_a_global, sequential_channel_ids, B_e, B_a, B_out, ...
    MAC_el, MAC_az, MAC_total);
if height(family) ~= 961 || numel(unique(family.subset_id)) ~= 961
    error('enumerate_stage7_rectangular_subsets:Count', ...
        'The registered family must contain exactly 961 unique subsets.');
end
end
