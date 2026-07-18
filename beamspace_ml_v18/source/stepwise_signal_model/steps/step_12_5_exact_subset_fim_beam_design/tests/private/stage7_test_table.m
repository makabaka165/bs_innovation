function table_out = stage7_test_table(case_id, metric, tolerance, pass_flag)
%STAGE7_TEST_TABLE Build and enforce one registered test table.

case_id = string(case_id(:));
metric = metric(:);
tolerance = tolerance(:);
pass_flag = logical(pass_flag(:));
if isscalar(tolerance) && numel(metric) > 1
    tolerance = repmat(tolerance, numel(metric), 1);
end
table_out = table(case_id, metric, tolerance, pass_flag);
end
