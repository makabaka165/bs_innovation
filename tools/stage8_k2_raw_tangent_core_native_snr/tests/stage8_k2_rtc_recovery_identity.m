function stage8_k2_rtc_recovery_identity(repo,runtime)
identity=stage8_k2_rtc_code_identity(repo);
gates=jsondecode(fileread(fullfile(runtime,'controller','gates.json')));
assert(gates.pass && gates.test_count==18 && strcmp(identity.source_hash,gates.source_hash));
archive=fullfile(runtime,'backup','launch_incident_d4e2517');
formal=jsondecode(fileread(fullfile(archive,'controller','formal_identity.json')));
assert(~strcmp(identity.head,formal.head));
formal.head=identity.head;
formal.source_hash=identity.source_hash;
formal.controller_fix_commit=identity.head;
formal.recovery_policy='ARCHIVE_BYTE_IDENTICAL_THEN_RECOMPUTE_WITH_STRICT_NEW_IDENTITY';
formal.recovery_archive_hash=stage8_k2_rtc_file_sha256(fullfile(archive,'archive_manifest.json'));
stage8_k2_rtc_write_json(fullfile(runtime,'controller','recovered_identity.json'),formal);
fprintf('RECOVERY IDENTITY: %s %s\n',identity.head,identity.source_hash);
end
