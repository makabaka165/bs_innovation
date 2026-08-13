function [context, audit] = stage8_k2_wacb_adopt_formal_identity( ...
    context, repo_dir, runtime_root, preflight)
%STAGE8_K2_WACB_ADOPT_FORMAL_IDENTITY Validate a control-only head migration.

formal_path = fullfile(runtime_root, 'formal_execution_state.mat');
audit = struct('pass', true, 'mode', 'FRESH', 'formal_head', '', ...
    'current_head', char(preflight.head), 'changed_paths', strings(0, 1));
if ~isfile(formal_path)
    context.formal_identity_audit = audit;
    return
end

loaded = load(formal_path, 'formal_state', '-mat');
if ~isfield(loaded, 'formal_state') || ~isstruct(loaded.formal_state) || ...
        ~isfield(loaded.formal_state, 'formal_head') || ...
        ~isfield(loaded.formal_state, 'code_identity')
    error('stage8_k2_wacb_adopt_formal_identity:Schema', ...
        'The existing formal identity state is incomplete.');
end
formal = loaded.formal_state;
formal_head = char(string(formal.formal_head));
current_head = char(string(preflight.head));
audit.formal_head = formal_head;

if strcmp(formal_head, current_head)
    if ~strcmp(char(string(formal.code_identity)), ...
            context.code_identity.tree_hash)
        error('stage8_k2_wacb_adopt_formal_identity:Code', ...
            'Formal HEAD is unchanged but the code identity differs.');
    end
    context.formal_identity_audit = audit;
    return
end

% The only permitted post-registration changes are execution control and
% this compatibility gate. Scientific MATLAB/plotting/test files remain
% bound to the registered formal HEAD by the path allow-list below.
if ~git_is_ancestor(repo_dir, formal_head, current_head)
    error('stage8_k2_wacb_adopt_formal_identity:Ancestry', ...
        'The current HEAD is not a descendant of the registered formal HEAD.');
end
changed = git_name_only(repo_dir, formal_head, current_head);
allowed = [ ...
    "tools/stage8_k2_white_snr_all_classical_baselines/matlab/stage8_k2_wacb_adopt_formal_identity.m"; ...
    "tools/stage8_k2_white_snr_all_classical_baselines/matlab/stage8_k2_wacb_registry_prepare.m"; ...
    "tools/stage8_k2_white_snr_all_classical_baselines/matlab/stage8_k2_wacb_run.m"; ...
    "tools/stage8_k2_white_snr_all_classical_baselines/matlab/stage8_k2_wacb_verify.m"; ...
    "tools/stage8_k2_white_snr_all_classical_baselines/powershell/Stage8K2WACBController.ps1"; ...
    "tools/stage8_k2_white_snr_all_classical_baselines/tests/test_scheduled_controller_state_machine.ps1" ];
unexpected = setdiff(changed, allowed);
if ~isempty(unexpected)
    error('stage8_k2_wacb_adopt_formal_identity:ScientificDelta', ...
        'Post-registration scientific files changed: %s', ...
        char(strjoin(unexpected, ', ')));
end

if strlength(string(formal.code_identity)) ~= 64 || ...
        strlength(string(context.code_identity.tree_hash)) ~= 64
    error('stage8_k2_wacb_adopt_formal_identity:HashSchema', ...
        'Formal or current code identity is not a SHA-256 digest.');
end
context.code_identity.tree_hash = char(string(formal.code_identity));
context.code_identity.formal_head = formal_head;
context.code_identity.current_head = current_head;
context.code_identity.execution_control_only = true;
context.context_hash = stage8_k2_wacb_stable_hash( ...
    context.constants.protocol, context.evidence44.identity, ...
    context.evidence46.identity, context.plan.local_domain.domain_hash, ...
    context.plan.stage8_measurement_plan_hash, ...
    context.code_identity.tree_hash, context.constants.source_commit);
audit.mode = 'EXECUTION_CONTROL_ONLY_MIGRATION';
audit.changed_paths = changed;
context.formal_identity_audit = audit;
end

function pass = git_is_ancestor(repo_dir, ancestor, descendant)
git_args = sprintf('merge-base --is-ancestor %s %s', ancestor, descendant);
[status, ~] = system(sprintf('git -C "%s" %s', repo_dir, git_args));
pass = status == 0;
end

function paths = git_name_only(repo_dir, ancestor, descendant)
git_args = sprintf('diff --name-only --no-renames %s..%s', ancestor, descendant);
[status, output] = system(sprintf('git -C "%s" %s', repo_dir, git_args));
if status ~= 0
    error('stage8_k2_wacb_adopt_formal_identity:Git', ...
        'Unable to inspect the formal-to-current Git delta.');
end
lines = splitlines(string(strtrim(output)));
lines = lines(strlength(lines) > 0);
paths = replace(lines, '\\', '/');
paths = replace(paths, '"', '');
end
