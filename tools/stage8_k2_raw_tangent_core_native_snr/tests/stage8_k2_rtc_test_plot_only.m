function manifest=stage8_k2_rtc_test_plot_only(repo,fixture_dir,output_dir)
old_path=path;
cleanup=onCleanup(@() path(old_path)); %#ok<NASGU>
restoredefaultpath;
addpath(fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','plotting'));
assert(exist('stage8_k2_rtc_fit_core','file')==0);
manifest=stage8_k2_rtc_plot_from_committed_data(fixture_dir,output_dir);
end
