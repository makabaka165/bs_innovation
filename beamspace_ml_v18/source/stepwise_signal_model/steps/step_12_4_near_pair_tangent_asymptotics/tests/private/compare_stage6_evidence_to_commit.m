function [comparison, summary] = compare_stage6_evidence_to_commit( ...
    repo_dir, old_commit, current_step_dir, contract, opts)
%COMPARE_STAGE6_EVIDENCE_TO_COMMIT Read old CSVs from Git and compare them.

if nargin < 5 || isempty(opts), opts = struct(); end
if ~(isstruct(opts) && isscalar(opts) && isempty(fieldnames(opts)))
    error('compare_stage6_evidence_to_commit:Options', ...
        'No compare-to-commit options are currently supported.');
end
if isstring(repo_dir), repo_dir = char(repo_dir); end
if isstring(current_step_dir), current_step_dir = char(current_step_dir); end
if isstring(old_commit), old_commit = char(old_commit); end
locked_old_commit = '17c2022aea3be4d1c6b090aa771e7253c79c858e';
if ~(ischar(repo_dir) && isrow(repo_dir) && exist(repo_dir, 'dir') == 7 && ...
        ischar(current_step_dir) && isrow(current_step_dir) && ...
        exist(current_step_dir, 'dir') == 7 && strcmpi(old_commit, locked_old_commit))
    error('compare_stage6_evidence_to_commit:Inputs', ...
        'The repository, current step, and locked historical commit are required.');
end
repo_root = canonical_path_local(repo_dir);
step_root = canonical_path_local(current_step_dir);
prefix = [repo_root, filesep];
if ~startsWith(lower(step_root), lower(prefix))
    error('compare_stage6_evidence_to_commit:StepPath', ...
        'current_step_dir must be inside repo_dir.');
end
step_relative = replace(string(step_root(numel(prefix) + 1:end)), '\', '/');
old_step_dir = tempname;
mkdir(old_step_dir);
cleanup = onCleanup(@() rmdir(old_step_dir, 's'));
for index = 1:height(contract)
    relative = replace(string(contract.relative_path(index)), '\', '/');
    git_path = step_relative + "/" + relative;
    validate_git_path_local(git_path);
    command = sprintf('git -C "%s" show "%s:%s"', ...
        repo_root, lower(old_commit), char(git_path));
    [status, output] = system(command);
    if status ~= 0, continue; end
    destination = fullfile(old_step_dir, char(relative));
    parent = fileparts(destination);
    if exist(parent, 'dir') ~= 7, mkdir(parent); end
    fid = fopen(destination, 'wb');
    if fid < 0
        error('compare_stage6_evidence_to_commit:TemporaryFile', ...
            'Unable to create the temporary historical CSV.');
    end
    file_cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, unicode2native(output, 'UTF-8'), 'uint8');
    clear file_cleanup;
end
[comparison, summary] = compare_stage6_evidence_directories( ...
    old_step_dir, current_step_dir, contract, struct());
end

function path_now = canonical_path_local(path_now)
path_now = char(java.io.File(path_now).getCanonicalPath());
end

function validate_git_path_local(path_now)
text = char(path_now);
if isempty(text) || startsWith(text, '/') || ...
        ~isempty(regexp(text, '^[A-Za-z]:', 'once')) || ...
        ~isempty(regexp(text, '["\r\n]', 'once')) || ...
        any(split(string(text), '/') == "..")
    error('compare_stage6_evidence_to_commit:GitPath', ...
        'Only safe repository-relative Git paths are accepted.');
end
end
