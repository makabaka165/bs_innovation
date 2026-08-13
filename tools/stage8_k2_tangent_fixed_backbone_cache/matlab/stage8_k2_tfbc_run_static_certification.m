function summary = stage8_k2_tfbc_run_static_certification(fixture)
%STAGE8_K2_TFBC_RUN_STATIC_CERTIFICATION Certify both frozen shapes.

domain = fixture.context.plan.local_domain;
single_pass = 0;
canonical_pair_pass = 0;
ordered_pair_pass = 0;
max_G_relative_error = 0;
rank_mismatch_count = 0;
singular_value_mismatch_count = 0;
threshold_mismatch_count = 0;
for identity_index = 1:numel(fixture.identities)
    identity = fixture.identities(identity_index);
    model = identity.model;
    provider = identity.provider_timed;
    points = sortrows(domain.candidate_points_deg, [1, 2]);
    for first = 1:size(points, 1)
        [pass, error_now, rank_mismatch, sigma_mismatch, tau_mismatch] = ...
            compare_local(points(first, :), model, domain, provider);
        single_pass = single_pass + double(pass);
        max_G_relative_error = max(max_G_relative_error, error_now);
        rank_mismatch_count = rank_mismatch_count + rank_mismatch;
        singular_value_mismatch_count = ...
            singular_value_mismatch_count + sigma_mismatch;
        threshold_mismatch_count = threshold_mismatch_count + tau_mismatch;
        for second = first:size(points, 1)
            [pass, error_now, rank_mismatch, sigma_mismatch, tau_mismatch] = ...
                compare_local(points([first, second], :), ...
                model, domain, provider);
            canonical_pair_pass = canonical_pair_pass + double(pass);
            max_G_relative_error = max(max_G_relative_error, error_now);
            rank_mismatch_count = rank_mismatch_count + rank_mismatch;
            singular_value_mismatch_count = ...
                singular_value_mismatch_count + sigma_mismatch;
            threshold_mismatch_count = ...
                threshold_mismatch_count + tau_mismatch;
        end
        for second = 1:size(points, 1)
            [pass, error_now, rank_mismatch, sigma_mismatch, tau_mismatch] = ...
                compare_local(points([first, second], :), ...
                model, domain, provider);
            ordered_pair_pass = ordered_pair_pass + double(pass);
            max_G_relative_error = max(max_G_relative_error, error_now);
            rank_mismatch_count = rank_mismatch_count + rank_mismatch;
            singular_value_mismatch_count = ...
                singular_value_mismatch_count + sigma_mismatch;
            threshold_mismatch_count = ...
                threshold_mismatch_count + tau_mismatch;
        end
    end
end
identity_rejection_pass = rejection_local(fixture, 'IDENTITY');
off_grid_rejection_pass = rejection_local(fixture, 'OFF_GRID');
domain_rejection_pass = rejection_local(fixture, 'DOMAIN');
phase_rejection_pass = rejection_local(fixture, 'PHASE');
pass = single_pass == 42 && canonical_pair_pass == 462 && ...
    ordered_pair_pass == 882 && max_G_relative_error == 0 && ...
    rank_mismatch_count == 0 && singular_value_mismatch_count == 0 && ...
    threshold_mismatch_count == 0 && identity_rejection_pass && ...
    off_grid_rejection_pass && domain_rejection_pass && ...
    phase_rejection_pass;
summary = table(single_pass, canonical_pair_pass, ordered_pair_pass, ...
    max_G_relative_error, rank_mismatch_count, ...
    singular_value_mismatch_count, threshold_mismatch_count, ...
    identity_rejection_pass, off_grid_rejection_pass, ...
    domain_rejection_pass, phase_rejection_pass, pass, ...
    'VariableNames', {'single_pass','canonical_pair_pass', ...
    'ordered_pair_pass','max_G_relative_error','rank_mismatch_count', ...
    'singular_value_mismatch_count','threshold_mismatch_count', ...
    'identity_rejection_pass','off_grid_rejection_pass', ...
    'domain_rejection_pass','phase_rejection_pass','pass'});
assert(pass, 'stage8_k2_tfbc_run_static_certification:Failed', ...
    'The frozen 42/462/882 static certification failed.');
end

function [pass, error_now, rank_mismatch, sigma_mismatch, tau_mismatch] = ...
    compare_local(angles, model, domain, provider)
[legacy, ~, legacy_info] = stage8_k2_tfbc_get_manifold( ...
    angles, model, domain, provider, struct('mode','LEGACY_FULL'));
[cached, ~, cache_info] = stage8_k2_tfbc_get_manifold( ...
    angles, model, domain, provider, struct('mode','REGISTERED_CACHE'));
error_now = norm(legacy - cached, 'fro') / max(norm(legacy, 'fro'), realmin);
rank_mismatch = double(legacy_info.rank_Gseq ~= cache_info.rank_Gseq);
sigma_mismatch = double(~isequal(legacy_info.singular_values_Gseq, ...
    cache_info.singular_values_Gseq));
tau_mismatch = double(~isequal(legacy_info.rank_threshold_Gseq, ...
    cache_info.rank_threshold_Gseq));
pass = isequal(legacy, cached) && rank_mismatch == 0 && ...
    sigma_mismatch == 0 && tau_mismatch == 0;
end

function pass = rejection_local(fixture, mode)
identity = fixture.identities(1);
model = identity.model;
domain = fixture.context.plan.local_domain;
provider = identity.provider_timed;
angles = domain.candidate_points_deg(1, :);
switch mode
    case 'IDENTITY'
        model.fixed_measurement_hash = repmat('0', 1, 64);
    case 'OFF_GRID'
        angles(1) = angles(1) + 0.01;
    case 'DOMAIN'
        domain.domain_hash = repmat('0', 1, 64);
    case 'PHASE'
        model.phase_factor = 2;
end
pass = false;
try
    stage8_k2_tfbc_get_manifold(angles, model, domain, provider, ...
        struct('mode','REGISTERED_CACHE'));
catch exception
    pass = strcmp(exception.identifier, ...
        'stage8_k2_tfbc_get_manifold:ContractMiss');
end
end
