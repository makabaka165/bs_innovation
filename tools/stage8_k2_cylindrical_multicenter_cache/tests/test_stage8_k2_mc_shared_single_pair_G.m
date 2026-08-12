function result = test_stage8_k2_mc_shared_single_pair_G(fixture, ~)
%TEST_STAGE8_K2_MC_SHARED_SINGLE_PAIR_G Check independent single/pair G.
center_index = find([fixture.centers.column_offset] == 96, 1);
noise_index = 1;
bundle = fixture.bundles(center_index,noise_index);
provider = fixture.providers(noise_index);
adapter = fixture.adapters(center_index,noise_index);
keys = sortrows(bundle.local_domain.candidate_points_deg,[1,2]);
single_error = 0;
pair_error = 0;
for index = [1,size(keys,1)]
    shared = stage8_k2_mc_get_manifold(keys(index,:),bundle.model, ...
        bundle.local_domain,provider,adapter);
    direct = stage8_k2_tcc_build_g_direct(keys(index,:),bundle.model,struct());
    single_error = max(single_error,relative_error_local(shared,direct));
end
pair = [keys(1,:);keys(end,:)];
shared = stage8_k2_mc_get_manifold(pair,bundle.model,bundle.local_domain, ...
    provider,adapter);
direct = stage8_k2_tcc_build_g_direct(pair,bundle.model,struct());
pair_error = relative_error_local(shared,direct);
pass = single_error <= 1e-10 && pair_error <= 1e-10;
assert(pass, 'test_stage8_k2_mc_shared_single_pair_G:Failed');
result = struct('pass',pass,'single_error',single_error, ...
    'pair_error',pair_error);
end
function value = relative_error_local(actual,reference)
value = norm(actual-reference,'fro')/max(norm(reference,'fro'),realmin);
end
