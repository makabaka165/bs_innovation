function result = test_music_two_peak_fixture()
%TEST_MUSIC_TWO_PEAK_FIXTURE Verify deterministic plateau and peak selection.

az = [0, 1, 2, 3, 4];
el = [10, 11, 12, 13];
spectrum = zeros(numel(az), numel(el));
spectrum(2, 2) = 9;
spectrum(2, 3) = 9;
spectrum(5, 4) = 7;
spectrum(4, 1) = 5;
picked = stage8_k2_cb_peak_picker(spectrum, az, el);
assert(picked.valid && isequal(picked.angles_hat_deg, [1, 11; 4, 13]) && ...
    isequal(picked.selected_plateau_sizes, [2, 1]), ...
    'test_music_two_peak_fixture:Peaks', ...
    'Peak picker did not collapse the plateau or select the top two peaks.');
result = struct('pass', true, 'angles_hat_deg', picked.angles_hat_deg);
fprintf('test_music_two_peak_fixture PASS\n');
end
