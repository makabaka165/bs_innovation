function stage8_k2_rtc_status_write(runtime, state, completed, detail)
status = struct('state',char(state),'completed',completed,'detail',char(detail), ...
    'utc',char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'")));
stage8_k2_rtc_write_json(fullfile(runtime,'status','latest.json'),status);
end
