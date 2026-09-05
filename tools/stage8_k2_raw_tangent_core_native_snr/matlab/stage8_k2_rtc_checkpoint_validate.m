function checkpoint = stage8_k2_rtc_checkpoint_validate(filename, spec, domain, identity, prepared)
loaded = load(filename,'checkpoint');
assert(isfield(loaded,'checkpoint'),'RTC:CheckpointSchema','Missing checkpoint.');
checkpoint = loaded.checkpoint;
required = {'payload_hash','spec','domain','source_hash','truth_hash', ...
    'noise_seed','noise_hash','clean_hash','observation_hash','snr','rows','diagnostics', ...
    'code_identity','registry_hash','beamwidth_hash','configuration_hash'};
assert(all(isfield(checkpoint,required)),'RTC:CheckpointSchema','Incomplete checkpoint.');
payload = rmfield(checkpoint,'payload_hash');
assert(strcmp(stage8_k2_rtc_hash(payload),checkpoint.payload_hash),'RTC:CheckpointHash','Corrupt checkpoint.');
assert(isequaln(checkpoint.spec,spec) && string(checkpoint.domain)==string(domain),'RTC:CheckpointIdentity','Wrong scenario/domain.');
assert(strcmp(checkpoint.code_identity.source_hash,identity.source_hash) && ...
    strcmp(checkpoint.code_identity.head,identity.head),'RTC:CheckpointCode','Code identity mismatch.');
assert(strcmp(checkpoint.registry_hash,prepared.registry_hash) && ...
    strcmp(checkpoint.beamwidth_hash,prepared.beamwidth_hash) && ...
    strcmp(checkpoint.configuration_hash,prepared.configuration_hash),'RTC:CheckpointContract','Frozen contract mismatch.');
c = stage8_k2_rtc_constants();
if string(domain)=="BEAMSPACE", expected = c.method_ids(1:3); else, expected = c.method_ids(4:8); end
assert(height(checkpoint.rows)==numel(expected) && isequal(checkpoint.rows.method_id,expected));
assert(all(checkpoint.rows.scenario_id==spec.scenario_id) && ...
    all(checkpoint.rows.observation_hash==string(checkpoint.observation_hash)));
assert(abs(checkpoint.snr.nominal_snr_db-spec.nominal_snr_db)<=1e-12);
seed = spec.element_noise_seed;
dimension = 2080;
if string(domain)=="BEAMSPACE", seed=spec.beam_noise_seed; dimension=15; end
assert(checkpoint.noise_seed==seed);
snr = checkpoint.snr;
assert(abs(10*log10(snr.signal_energy/(dimension*spec.L*snr.noise_variance))-spec.nominal_snr_db)<=1e-12);
assert(abs(10*log10(snr.signal_energy/snr.noise_energy)-snr.realized_snr_db)<=1e-12);
end
