function result = test_fbss_coherent_rank_restoration(context)
%TEST_FBSS_COHERENT_RANK_RESTORATION Verify P=2 restores signal rank two.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
fixture = stage8_k2_sb_test_vertical_fixture(context, "WHITE");
raw_values = svd(fixture.R_signal);
raw_rank = nnz(raw_values > max(size(fixture.R_signal)) * ...
    eps(max(raw_values)));
signal_fb = fixture.R_fb - fixture.R_noise_subarray;
fb_values = svd(signal_fb);
fb_rank = nnz(fb_values > 1e-8 * max(fb_values));
assert(raw_rank == 1 && fb_rank == 2, ...
    'test_fbss_coherent_rank_restoration:Rank', ...
    'The coherent fixture did not change from rank one to rank two.');
result = struct('pass', true, 'raw_rank', raw_rank, ...
    'fbss_signal_rank', fb_rank, 'fbss_singular_values', fb_values(1:3));
end

function [context, cleanup] = context_local(context)
cleanup = [];
if nargin < 1 || isempty(context)
    test_dir = fileparts(mfilename('fullpath'));
    repo_dir = fileparts(fileparts(fileparts(test_dir)));
    cleanup = stage8_k2_sb_add_paths(repo_dir);
    context = stage8_k2_sb_build_context(repo_dir);
end
end
