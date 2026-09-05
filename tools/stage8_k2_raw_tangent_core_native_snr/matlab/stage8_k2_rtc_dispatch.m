function stage8_k2_rtc_dispatch(mode,repo,runtime)
cleanup=stage8_k2_rtc_add_paths(repo); %#ok<NASGU>
try
    switch upper(mode)
        case {'BEAMSPACE','ELEMENT'}, stage8_k2_rtc_run(repo,runtime,upper(mode));
        case 'FINALIZE', stage8_k2_rtc_finalize(repo,runtime);
        case 'AUDIT', stage8_k2_rtc_verify(repo,runtime);
        otherwise, error('RTC:Mode','Unknown dispatch mode.');
    end
catch exception
    stage8_k2_rtc_write_json(fullfile(runtime,'status','hard_stop.json'), ...
        struct('state','HARD_STOPPED','mode',mode,'identifier',exception.identifier, ...
        'message',exception.message,'stack',exception.stack));
    rethrow(exception);
end
end
