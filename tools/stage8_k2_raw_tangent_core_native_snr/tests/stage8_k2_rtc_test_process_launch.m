function stage8_k2_rtc_test_process_launch(repo,runtime)
script=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','powershell','Stage8K2RTCController.ps1');
[status,output]=system(sprintf('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%s" -Action TestProbe -RepoDir "%s" -RuntimeRoot "%s"',script,repo,runtime));
assert(status==0,'RTC:ActualProcessTest','%s',output);
fprintf('ACTUAL PROCESS INVENTORY AND TICK PASS\n');
end
