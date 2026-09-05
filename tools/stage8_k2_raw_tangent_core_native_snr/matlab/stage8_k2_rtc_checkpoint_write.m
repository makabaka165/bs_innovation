function stage8_k2_rtc_checkpoint_write(filename, checkpoint)
assert(~isfile(filename),'RTC:CheckpointExists','Checkpoint already exists.');
temporary = [char(filename) '.tmp'];
assert(~isfile(temporary),'RTC:Temporary','Temporary checkpoint already exists.');
checkpoint.payload_hash = stage8_k2_rtc_hash(checkpoint);
save(temporary,'checkpoint','-v7');
loaded = load(temporary,'-mat','checkpoint');
assert(isequaln(checkpoint,loaded.checkpoint),'RTC:Roundtrip','Checkpoint roundtrip failed.');
[ok,message] = movefile(temporary,filename);
assert(ok,'RTC:CheckpointRename','%s',message);
end
