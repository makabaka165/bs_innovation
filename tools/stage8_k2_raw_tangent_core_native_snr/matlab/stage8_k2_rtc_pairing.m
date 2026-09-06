function pairs = stage8_k2_rtc_pairing(results)
% Paired outcomes are restricted to identical observations within one domain.
c = stage8_k2_rtc_constants();
cells = cell(0,1);
for profile = c.profile_ids.'
    for snr = c.snr_db_values
        for domain = ["BEAMSPACE","ELEMENT"]
            t = results(results.profile_id==profile & results.nominal_snr_db==snr & results.domain==domain,:);
            methods = c.beamspace_method_ids;
            if domain=="ELEMENT", methods=c.element_method_ids; end
            for a = 1:numel(methods)-1
                for b = a+1:numel(methods)
                    A = sortrows(t(t.method_id==methods(a),:),'scenario_id');
                    B = sortrows(t(t.method_id==methods(b),:),'scenario_id');
                    assert(height(A)==height(B) && isequal(A.scenario_id,B.scenario_id));
                    assert(all(A.observation_hash==B.observation_hash) && all(A.applicable & B.applicable));
                    row = struct('profile_id',profile,'L',8,'nominal_snr_db',snr, ...
                        'domain',domain,'method_A',methods(a),'method_B',methods(b),'paired_count',height(A));
                    for metric = ["fit_valid","localization_success_01bw","resolution_success"]
                        av = logical(A.(metric)); bv = logical(B.(metric));
                        row.(metric+"_both") = nnz(av & bv);
                        row.(metric+"_only_A") = nnz(av & ~bv);
                        row.(metric+"_only_B") = nnz(~av & bv);
                        row.(metric+"_neither") = nnz(~av & ~bv);
                    end
                    common = A.fit_valid & B.fit_valid;
                    delta = A.joint_RMSE_deg(common)-B.joint_RMSE_deg(common);
                    assert(all(isfinite(delta)));
                    row.common_valid_count = nnz(common);
                    row.rmse_A_wins = nnz(delta < -c.paired_tie_tolerance_deg);
                    row.rmse_ties = nnz(abs(delta)<=c.paired_tie_tolerance_deg);
                    row.rmse_B_wins = nnz(delta > c.paired_tie_tolerance_deg);
                    row.tie_tolerance_deg = c.paired_tie_tolerance_deg;
                    cells{end+1,1} = row; %#ok<AGROW>
                end
            end
        end
    end
end
pairs = struct2table(vertcat(cells{:}));
end
