function prepared = stage8_k2_rtc_prepare(repo, runtime)
c = stage8_k2_rtc_constants();
assert(strcmp(char(java.io.File(runtime).getCanonicalPath()),c.runtime_root));
for directory = ["registry","beamwidth","checkpoints/beamspace","checkpoints/element", ...
        "status","logs","artifacts","controller","tests"]
    target = fullfile(runtime,directory);
    if ~isfolder(target), mkdir(target); end
end
context = stage8_k2_rtc_build_context(repo);
registry = stage8_k2_rtc_build_registry();
beamwidth = stage8_k2_rtc_measure_beamwidths(context);
prepared = struct('registry',registry,'beamwidth',beamwidth, ...
    'registry_hash',stage8_k2_rtc_hash(registry),'configuration_hash',context.configuration_hash, ...
    'beamwidth_hash',char(beamwidth.beamwidth_contract_hash(1)));
filename = fullfile(runtime,'registry','prepared.mat');
if isfile(filename)
    old = load(filename,'prepared');
    assert(isequaln(old.prepared,prepared),'RTC:PreparedIdentity','Prepared registry changed.');
else
    assert(~isfile([filename '.tmp']));
    save([filename '.tmp'],'prepared','-v7');
    movefile([filename '.tmp'],filename);
end
writetable(registry,fullfile(repo,'innovation-mining','58_stage8_k2_raw_tangent_registry.csv'));
writetable(beamwidth,fullfile(repo,'innovation-mining','58_stage8_k2_raw_tangent_beamwidth_contract.csv'));
writetable(registry,fullfile(runtime,'registry','registry.csv'));
writetable(beamwidth,fullfile(runtime,'beamwidth','beamwidth.csv'));
end
