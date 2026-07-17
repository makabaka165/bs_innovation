function spec = stage5_design_spec(cfg, Kq_mode, noise_sigma)
%STAGE5_DESIGN_SPEC Return a small registered design fixture.

if nargin < 3
    noise_sigma = 0;
end
switch char(Kq_mode)
    case 'Q1_K2'
        angles = [7.6, 10.0; 8.4, 10.0];
        sources = [1, exp(0.2j), 0.9 * exp(-0.3j); ...
            0.8 * exp(0.4j), 1.1 * exp(-0.2j), 0.7 * exp(0.6j)];
        groups = [1; 1];
    case 'Q2_K1_K1'
        angles = [7.6, 9.8; 8.4, 10.2];
        sources = [1, exp(0.2j), 0.9 * exp(-0.3j); ...
            0.8 * exp(0.4j), 1.1 * exp(-0.2j), 0.7 * exp(0.6j)];
        groups = [1; 2];
    case 'K1'
        angles = [8.2, 10.0];
        sources = [1, exp(0.2j), 0.9 * exp(-0.3j)];
        groups = 1;
    otherwise
        error('stage5_design_spec:Mode', 'Unknown design mode: %s.', Kq_mode);
end
if noise_sigma > 0
    noise_kind = 'white';
else
    noise_kind = 'none';
end
spec = struct('name', ['design_', lower(Kq_mode)], ...
    'data_split', 'DESIGN', 'target_angles_deg', angles, ...
    'source_snapshots', sources, 'group_index', groups, ...
    'noise_kind', noise_kind, 'noise_sigma', noise_sigma, ...
    'seed', 125001, 'aperture_index', 1:cfg.beam.subNaz);
end
