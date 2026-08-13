function stage8_k2_wacb_write_json_atomic(path_now, value)
%STAGE8_K2_WACB_WRITE_JSON_ATOMIC Encode and atomically replace JSON.

encoded = jsonencode(value, 'PrettyPrint', true);
stage8_k2_wacb_write_text_atomic(path_now, [encoded, newline]);
end
