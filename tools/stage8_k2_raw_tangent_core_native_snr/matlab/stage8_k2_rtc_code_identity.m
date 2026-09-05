function identity = stage8_k2_rtc_code_identity(repo)
paths = stage8_k2_rtc_source_paths(repo);
rows = cell(numel(paths),1);
for k = 1:numel(paths)
    content = fileread(fullfile(repo,paths{k}));
    content = strrep(content,sprintf('\r\n'),sprintf('\n'));
    rows{k} = struct('path',string(paths{k}),'sha256',string(stage8_k2_rtc_hash(content)));
end
files = struct2table(vertcat(rows{:}));
[status,head] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
assert(status==0);
identity = struct('head',strtrim(head),'source_hash',stage8_k2_rtc_hash(files),'files',files);
end
