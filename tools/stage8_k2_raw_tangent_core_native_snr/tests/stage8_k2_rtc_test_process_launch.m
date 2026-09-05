function stage8_k2_rtc_test_process_launch(repo,runtime,pwsh)
script=fullfile(repo,'tools','stage8_k2_raw_tangent_core_native_snr','powershell','Stage8K2RTCController.ps1');
hosts={fullfile(getenv('SystemRoot'),'System32','WindowsPowerShell','v1.0','powershell.exe'),pwsh};
for k=1:numel(hosts)
    [status,output]=system(sprintf('"%s" -NoProfile -ExecutionPolicy Bypass -File "%s" -Action TestProbe -RepoDir "%s" -RuntimeRoot "%s"',hosts{k},script,repo,runtime));
    assert(status==0,'RTC:ActualProcessTest','%s',output);
end
fprintf('ACTUAL PROCESS INVENTORY AND TICK PASS\n');
end
