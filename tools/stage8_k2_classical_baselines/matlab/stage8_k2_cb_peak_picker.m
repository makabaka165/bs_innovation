function result = stage8_k2_cb_peak_picker(spectrum, az_grid_deg, el_grid_deg)
%STAGE8_K2_CB_PEAK_PICKER Select two deterministic 8-neighbor local peaks.

if ~(isnumeric(spectrum) && isreal(spectrum) && ...
        isequal(size(spectrum), [numel(az_grid_deg), numel(el_grid_deg)]))
    error('stage8_k2_cb_peak_picker:Shape', ...
        'Spectrum dimensions must match the azimuth/elevation grids.');
end
finite_mask = isfinite(spectrum);
candidate = false(size(spectrum));
for row = 1:size(spectrum, 1)
    for column = 1:size(spectrum, 2)
        if ~finite_mask(row, column)
            continue;
        end
        rows = max(1, row-1):min(size(spectrum, 1), row+1);
        columns = max(1, column-1):min(size(spectrum, 2), column+1);
        neighbors = spectrum(rows, columns);
        neighbors(row - rows(1) + 1, column - columns(1) + 1) = -Inf;
        candidate(row, column) = all( ...
            spectrum(row, column) >= neighbors(:));
    end
end

visited = false(size(spectrum));
peaks = repmat(peak_template_local(), 0, 1);
for row = 1:size(spectrum, 1)
    for column = 1:size(spectrum, 2)
        if ~candidate(row, column) || visited(row, column)
            continue;
        end
        value = spectrum(row, column);
        queue = zeros(nnz(candidate), 2);
        queue(1, :) = [row, column];
        head = 1;
        tail = 1;
        visited(row, column) = true;
        component = zeros(nnz(candidate), 2);
        component_count = 0;
        while head <= tail
            current = queue(head, :);
            head = head + 1;
            component_count = component_count + 1;
            component(component_count, :) = current;
            rows = max(1, current(1)-1):min(size(spectrum, 1), current(1)+1);
            columns = max(1, current(2)-1):min(size(spectrum, 2), current(2)+1);
            for next_row = rows
                for next_column = columns
                    if candidate(next_row, next_column) && ...
                            ~visited(next_row, next_column) && ...
                            spectrum(next_row, next_column) == value
                        tail = tail + 1;
                        queue(tail, :) = [next_row, next_column];
                        visited(next_row, next_column) = true;
                    end
                end
            end
        end
        component = component(1:component_count, :);
        coordinates = [az_grid_deg(component(:, 1)).', ...
            el_grid_deg(component(:, 2)).'];
        [~, order] = sortrows(coordinates, [1, 2]);
        representative = component(order(1), :);
        peaks(end + 1, 1) = struct('value', value, ...
            'row', representative(1), 'column', representative(2), ...
            'az_deg', az_grid_deg(representative(1)), ...
            'el_deg', el_grid_deg(representative(2)), ...
            'plateau_size', component_count); %#ok<AGROW>
    end
end

result = struct('valid', false, 'status', "MUSIC_FEWER_THAN_TWO_PEAKS", ...
    'angles_hat_deg', NaN(2, 2), 'peak_values', [NaN, NaN], ...
    'local_peak_count', numel(peaks), 'selected_plateau_sizes', [0, 0]);
if numel(peaks) < 2
    return;
end
ranking = zeros(numel(peaks), 4);
for index = 1:numel(peaks)
    ranking(index, :) = [-peaks(index).value, peaks(index).az_deg, ...
        peaks(index).el_deg, index];
end
[~, order] = sortrows(ranking, 1:4);
selected = peaks(order(1:2));
result.valid = true;
result.status = "MUSIC_TWO_PEAKS_VALID";
result.angles_hat_deg = [selected(1).az_deg, selected(1).el_deg; ...
    selected(2).az_deg, selected(2).el_deg];
result.peak_values = [selected.value];
result.selected_plateau_sizes = [selected.plateau_size];
end

function peak = peak_template_local()
peak = struct('value', -Inf, 'row', 0, 'column', 0, ...
    'az_deg', NaN, 'el_deg', NaN, 'plateau_size', 0);
end
