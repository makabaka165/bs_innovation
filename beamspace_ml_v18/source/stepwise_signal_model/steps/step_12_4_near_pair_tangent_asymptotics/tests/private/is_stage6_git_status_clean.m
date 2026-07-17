function flag = is_stage6_git_status_clean(status_porcelain)
%IS_STAGE6_GIT_STATUS_CLEAN Classify porcelain output without touching Git.

if isstring(status_porcelain)
    if ~isscalar(status_porcelain) || ismissing(status_porcelain)
        error('is_stage6_git_status_clean:Input', ...
            'status_porcelain must be a nonmissing scalar string or char vector.');
    end
    status_porcelain = char(status_porcelain);
elseif ~(ischar(status_porcelain) && (isrow(status_porcelain) || isempty(status_porcelain)))
    error('is_stage6_git_status_clean:Input', ...
        'status_porcelain must be a nonmissing scalar string or char vector.');
end

status_porcelain = regexprep(status_porcelain, '\r\n?', '\n');
status_porcelain = regexprep(status_porcelain, '\n+$', '');
flag = isempty(status_porcelain);
end
