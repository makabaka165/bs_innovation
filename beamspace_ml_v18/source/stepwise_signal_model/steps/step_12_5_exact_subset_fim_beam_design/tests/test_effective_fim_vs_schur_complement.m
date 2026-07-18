function table_out = test_effective_fim_vs_schur_complement(~)
%TEST_EFFECTIVE_FIM_VS_SCHUR_COMPLEMENT Validate deterministic elimination.

rng(712509, 'twister');
fixtures = { ...
    struct('K',1,'L',1,'rho',1,'corr',false), ...
    struct('K',1,'L',4,'rho',0,'corr',true), ...
    struct('K',2,'L',1,'rho',1,'corr',true), ...
    struct('K',2,'L',4,'rho',0,'corr',false), ...
    struct('K',2,'L',4,'rho',1,'corr',true)};
errors = zeros(numel(fixtures), 1);
case_id = strings(numel(fixtures), 1);
for index = 1:numel(fixtures)
    fixture = fixtures{index};
    r = fixture.K + 3;
    G = complex(randn(r, fixture.K), randn(r, fixture.K));
    if fixture.corr
        R = toeplitz(0.6 .^ (0:r - 1));
        W = complex(randn(r), randn(r));
        C = W' * R * W;
        T = build_psd_whitener(C, struct());
        G = T * W' * G;
    end
    dG = struct('azimuth', complex(randn(size(G)), randn(size(G))), ...
        'elevation', complex(randn(size(G)), randn(size(G))));
    if fixture.K == 1
        [S, ~] = construct_deterministic_source_matrix(1, fixture.L, ...
            0, 0, 0, 'K1');
    else
        [S, ~] = construct_deterministic_source_matrix(2, fixture.L, ...
            -3, fixture.rho, 0.4, 'K2');
    end
    projected = effective_deterministic_fim(G, dG, S, 1, struct());
    schur = effective_deterministic_fim_schur_reference(G, dG, S, 1);
    errors(index) = norm(projected.F - schur, 'fro') / ...
        max(norm(schur, 'fro'), realmin);
    case_id(index) = sprintf('K%d_L%d_RHO%.0f', ...
        fixture.K, fixture.L, fixture.rho);
end
table_out = stage7_test_table(case_id, errors, 1e-9, errors <= 1e-9);
end
