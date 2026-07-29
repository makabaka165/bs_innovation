function inventory = stage8_core_v2_2_directory_inventory(path_now)
%STAGE8_CORE_V2_2_DIRECTORY_INVENTORY Count real direct child entries.

path_text = string(path_now);
if ~isscalar(path_text) || strlength(path_text) == 0 || ...
        ~isfolder(path_text)
    error('stage8_core_v2_2_directory_inventory:Path', ...
        'path_now must identify one existing directory.');
end
entries = dir(char(path_text));
names = string({entries.name});
entries = entries(~ismember(names, [".", ".."])) ;
is_directory = [entries.isdir];
files = entries(~is_directory);
directories = entries(is_directory);
inventory = struct('path', char(path_text), ...
    'file_count', numel(files), ...
    'directory_count', numel(directories), ...
    'file_names', sort(string({files.name})), ...
    'directory_names', sort(string({directories.name})));
end
