classdef stage8_k2_tecs_cache_session < handle
    %STAGE8_K2_TECS_CACHE_SESSION Explicit scoped exact-cache state.

    properties (SetAccess = private)
        SchemaVersion
        RunId
        BaselineCommit
        KeySchemaHash
        Scope
        FixedMeasurementHash
        EnabledLayers
        Artifacts
        HitCount
        MissCount
        PhysicalProducerCallCount
        EntryCount
        BytesCurrent
        BytesPeak
        EvictionCount
        CollisionCount
        TruthLeakageCount
        ResetCount
    end

    properties (Access = private)
        Buckets
        PrebuiltBytes
        PrebuiltEntryCount
        FailureMode
        MemoryLimitBytes
    end

    methods
        function obj = stage8_k2_tecs_cache_session(config)
            required = {'run_id','baseline_commit','key_schema_hash', ...
                'scope','fixed_measurement_hash','enabled_layers'};
            if ~(isstruct(config) && isscalar(config) && ...
                    all(isfield(config, required)))
                error('stage8_k2_tecs_cache_session:Config', ...
                    'Session config is incomplete.');
            end
            obj.SchemaVersion = 'STAGE8_K2_TECS_CACHE_SESSION_V1';
            obj.RunId = char(string(config.run_id));
            obj.BaselineCommit = char(string(config.baseline_commit));
            obj.KeySchemaHash = char(string(config.key_schema_hash));
            obj.Scope = upper(char(string(config.scope)));
            obj.FixedMeasurementHash = ...
                char(string(config.fixed_measurement_hash));
            obj.EnabledLayers = cellstr(upper(string(config.enabled_layers)));
            obj.Artifacts = struct();
            if isfield(config, 'artifacts') && ~isempty(config.artifacts)
                obj.Artifacts = config.artifacts;
            end
            obj.MemoryLimitBytes = 536870912;
            if isfield(config, 'memory_limit_bytes')
                obj.MemoryLimitBytes = double(config.memory_limit_bytes);
            end
            obj.Buckets = containers.Map('KeyType','char','ValueType','any');
            obj.FailureMode = 'NONE';
            obj.initialize_prebuilt_local();
            obj.clear_counters();
        end

        function delete(obj)
            if ~isempty(obj.Buckets)
                remove(obj.Buckets, keys(obj.Buckets));
            end
        end

        function clear_counters(obj)
            obj.HitCount = 0;
            obj.MissCount = 0;
            obj.PhysicalProducerCallCount = 0;
            obj.EvictionCount = 0;
            obj.CollisionCount = 0;
            obj.TruthLeakageCount = 0;
            obj.ResetCount = 0;
            obj.EntryCount = obj.PrebuiltEntryCount + obj.Buckets.Count;
            obj.BytesCurrent = obj.PrebuiltBytes + ...
                obj.bucket_bytes_local();
            obj.BytesPeak = obj.BytesCurrent;
        end

        function flag = layer_enabled(obj, layer)
            flag = any(strcmpi(obj.EnabledLayers, char(string(layer))));
        end

        function set_failure_injection(obj, mode)
            mode = upper(char(string(mode)));
            allowed = {'NONE','LOOKUP_FAILURE','PRODUCER_FAILURE', ...
                'CORRUPT_NEXT_LOOKUP'};
            if ~ismember(mode, allowed)
                error('stage8_k2_tecs_cache_session:FailureMode', ...
                    'Unsupported failure-injection mode: %s.', mode);
            end
            obj.FailureMode = mode;
        end

        function mode = failure_mode(obj)
            mode = obj.FailureMode;
        end

        function [columns, info] = lookup_c1(obj, angles_deg, model)
            if strcmp(obj.FailureMode, 'LOOKUP_FAILURE')
                error('stage8_k2_tecs_cache_session:InjectedLookupFailure', ...
                    'Injected C1 lookup failure.');
            end
            if ~(isa(angles_deg, 'double') && ismatrix(angles_deg) && ...
                    size(angles_deg, 2) == 2 && ~isempty(angles_deg) && ...
                    all(isfinite(angles_deg(:))))
                error('stage8_k2_tecs_cache_session:C1Angles', ...
                    'C1 angles must be a finite double K-by-2 matrix.');
            end
            count = size(angles_deg, 1);
            columns = cell(count, 1);
            info = struct('cache_hit',false(count, 1), ...
                'identity_valid',false,'key_indices',NaN(count, 1), ...
                'key_error_deg',Inf(count, 1), ...
                'cache_miss_reason',repmat("NOT_RUN", count, 1), ...
                'value_copy_bytes',0,'entry_count',obj.EntryCount, ...
                'bytes_current',obj.BytesCurrent,'bytes_peak',obj.BytesPeak);
            if ~obj.layer_enabled('C1') || ~isfield(obj.Artifacts, 'C1')
                obj.MissCount = obj.MissCount + count;
                info.cache_miss_reason(:) = "LAYER_DISABLED_OR_ARTIFACT_MISSING";
                return;
            end
            artifact = obj.Artifacts.C1;
            identity_valid = isstruct(model) && isscalar(model) && ...
                isfield(model, 'fixed_measurement_hash') && ...
                strcmp(char(string(model.fixed_measurement_hash)), ...
                obj.FixedMeasurementHash) && ...
                strcmp(artifact.fixed_measurement_hash, ...
                obj.FixedMeasurementHash);
            if isfield(model, 'phase_factor')
                identity_valid = identity_valid && ...
                    isequal(double(model.phase_factor), ...
                    double(artifact.phase_factor));
            end
            info.identity_valid = identity_valid;
            if ~identity_valid
                obj.MissCount = obj.MissCount + count;
                info.cache_miss_reason(:) = "IDENTITY_REJECTED";
                return;
            end
            tolerance = double(artifact.key_tolerance_deg);
            for row = 1:count
                difference = max(abs(artifact.key_angles_deg - ...
                    angles_deg(row, :)), [], 2);
                [error_now, index] = min(difference);
                info.key_error_deg(row) = error_now;
                if ~isempty(index) && error_now <= tolerance
                    columns{row} = artifact.G(:, index);
                    info.cache_hit(row) = true;
                    info.key_indices(row) = index;
                    info.cache_miss_reason(row) = "NOT_APPLICABLE";
                    obj.HitCount = obj.HitCount + 1;
                    copy_probe = columns{row}; %#ok<NASGU>
                    copy_info = whos('copy_probe');
                    info.value_copy_bytes = info.value_copy_bytes + ...
                        double(copy_info.bytes);
                else
                    obj.MissCount = obj.MissCount + 1;
                    info.cache_miss_reason(row) = "OFF_GRID_EXACT_KEY";
                end
            end
            obj.update_peak_local(info.value_copy_bytes);
            info.entry_count = obj.EntryCount;
            info.bytes_current = obj.BytesCurrent;
            info.bytes_peak = obj.BytesPeak;
        end

        function [hit, value, info] = lookup_exact(obj, layer, key_payload)
            obj.reject_truth_local(key_payload);
            if strcmp(obj.FailureMode, 'LOOKUP_FAILURE')
                error('stage8_k2_tecs_cache_session:InjectedLookupFailure', ...
                    'Injected exact lookup failure.');
            end
            [hash, bytes] = stage8_k2_tecs_sha256( ...
                ['TECS_', upper(char(string(layer))), '_KEY'], key_payload);
            bucket_key = [upper(char(string(layer))), '|', hash];
            hit = false;
            value = [];
            info = struct('hash',hash,'payload_bytes',numel(bytes), ...
                'cache_hit',false,'collision',false);
            if ~isKey(obj.Buckets, bucket_key)
                obj.MissCount = obj.MissCount + 1;
                return;
            end
            entry = obj.Buckets(bucket_key);
            if ~isequal(entry.payload_bytes, bytes)
                obj.CollisionCount = obj.CollisionCount + 1;
                error('stage8_k2_tecs_cache_session:HashCollision', ...
                    'INTEGRATED_KEY_COLLISION_STOP: payload mismatch.');
            end
            if strcmp(obj.FailureMode, 'CORRUPT_NEXT_LOOKUP') || ...
                    ~strcmp(entry.value_hash, stage8_k2_tecs_sha256( ...
                    'TECS_IMMUTABLE_VALUE', entry.value))
                obj.FailureMode = 'NONE';
                error('stage8_k2_tecs_cache_session:CacheCorruption', ...
                    'Cached immutable value failed its stored hash.');
            end
            value = entry.value;
            hit = true;
            info.cache_hit = true;
            obj.HitCount = obj.HitCount + 1;
            value_probe = value; %#ok<NASGU>
            value_info = whos('value_probe');
            obj.update_peak_local(double(value_info.bytes));
        end

        function info = store_exact(obj, layer, key_payload, value)
            obj.reject_truth_local(key_payload);
            obj.reject_truth_local(value);
            [hash, bytes] = stage8_k2_tecs_sha256( ...
                ['TECS_', upper(char(string(layer))), '_KEY'], key_payload);
            bucket_key = [upper(char(string(layer))), '|', hash];
            value_hash = stage8_k2_tecs_sha256('TECS_IMMUTABLE_VALUE', value);
            if isKey(obj.Buckets, bucket_key)
                existing = obj.Buckets(bucket_key);
                if ~isequal(existing.payload_bytes, bytes)
                    obj.CollisionCount = obj.CollisionCount + 1;
                    error('stage8_k2_tecs_cache_session:HashCollision', ...
                        'INTEGRATED_KEY_COLLISION_STOP: insert collision.');
                end
                if ~strcmp(existing.value_hash, value_hash) || ...
                        ~isequaln(existing.value, value)
                    error('stage8_k2_tecs_cache_session:ImmutableEntry', ...
                        'An immutable entry cannot be replaced.');
                end
                info = struct('inserted',false,'hash',hash);
                return;
            end
            value_probe = value; %#ok<NASGU>
            value_info = whos('value_probe');
            entry = struct('payload_bytes',bytes,'value',value, ...
                'value_hash',value_hash,'accounted_bytes', ...
                double(numel(bytes) + value_info.bytes + 256));
            obj.Buckets(bucket_key) = entry;
            obj.EntryCount = obj.PrebuiltEntryCount + obj.Buckets.Count;
            obj.BytesCurrent = obj.PrebuiltBytes + obj.bucket_bytes_local();
            obj.update_peak_local(0);
            obj.enforce_memory_local();
            info = struct('inserted',true,'hash',hash);
        end

        function debug_inject_bucket(obj, layer, forced_hash, payload_bytes, value)
            if ~(isa(payload_bytes, 'uint8') && isvector(payload_bytes))
                error('stage8_k2_tecs_cache_session:DebugPayload', ...
                    'Injected payload must be uint8 bytes.');
            end
            bucket_key = [upper(char(string(layer))), '|', ...
                char(string(forced_hash))];
            value_probe = value; %#ok<NASGU>
            value_info = whos('value_probe');
            obj.Buckets(bucket_key) = struct( ...
                'payload_bytes',reshape(payload_bytes, 1, []), ...
                'value',value, ...
                'value_hash',stage8_k2_tecs_sha256( ...
                'TECS_IMMUTABLE_VALUE', value), ...
                'accounted_bytes',double(numel(payload_bytes) + ...
                value_info.bytes + 256));
            obj.EntryCount = obj.PrebuiltEntryCount + obj.Buckets.Count;
            obj.BytesCurrent = obj.PrebuiltBytes + obj.bucket_bytes_local();
            obj.update_peak_local(0);
        end

        function record_physical_producer_call(obj, count)
            obj.PhysicalProducerCallCount = ...
                obj.PhysicalProducerCallCount + double(count);
        end

        function reset(obj, reset_scope)
            reset_scope = upper(char(string(reset_scope)));
            if ~ismember(reset_scope, ...
                    {'TRIAL_INVOCATION','MEASUREMENT_IDENTITY_SESSION','ALL'})
                error('stage8_k2_tecs_cache_session:ResetScope', ...
                    'Unsupported reset scope: %s.', reset_scope);
            end
            if ~isempty(obj.Buckets)
                remove(obj.Buckets, keys(obj.Buckets));
            end
            obj.ResetCount = obj.ResetCount + 1;
            obj.EntryCount = obj.PrebuiltEntryCount;
            obj.BytesCurrent = obj.PrebuiltBytes;
            obj.BytesPeak = max(obj.BytesPeak, obj.BytesCurrent);
            if ismember(reset_scope, ...
                    {'MEASUREMENT_IDENTITY_SESSION','ALL'})
                obj.HitCount = 0;
                obj.MissCount = 0;
                obj.PhysicalProducerCallCount = 0;
            end
        end

        function output = snapshot(obj)
            output = struct( ...
                'schema_version',obj.SchemaVersion, ...
                'run_id',obj.RunId, ...
                'baseline_commit',obj.BaselineCommit, ...
                'key_schema_hash',obj.KeySchemaHash, ...
                'scope',obj.Scope, ...
                'fixed_measurement_hash',obj.FixedMeasurementHash, ...
                'enabled_layers',{obj.EnabledLayers}, ...
                'hit_count',obj.HitCount, ...
                'miss_count',obj.MissCount, ...
                'physical_producer_call_count', ...
                    obj.PhysicalProducerCallCount, ...
                'entry_count',obj.EntryCount, ...
                'bytes_current',obj.BytesCurrent, ...
                'bytes_peak',obj.BytesPeak, ...
                'eviction_count',obj.EvictionCount, ...
                'collision_count',obj.CollisionCount, ...
                'truth_leakage_count',obj.TruthLeakageCount, ...
                'reset_count',obj.ResetCount, ...
                'failure_mode',obj.FailureMode, ...
                'memory_limit_bytes',obj.MemoryLimitBytes);
        end
    end

    methods (Access = private)
        function initialize_prebuilt_local(obj)
            obj.PrebuiltBytes = 0;
            obj.PrebuiltEntryCount = 0;
            if isfield(obj.Artifacts, 'C1')
                artifact = obj.Artifacts.C1;
                required = {'artifact_hash','fixed_measurement_hash', ...
                    'key_angles_deg','G','entry_count','value_bytes', ...
                    'immutable'};
                if ~(isstruct(artifact) && isscalar(artifact) && ...
                        all(isfield(artifact, required)) && ...
                        artifact.immutable && artifact.entry_count == 21)
                    error('stage8_k2_tecs_cache_session:C1Artifact', ...
                        'C1 artifact validation failed.');
                end
                obj.PrebuiltBytes = double(artifact.value_bytes) + ...
                    numel(artifact.key_angles_deg) * 8 + 4096;
                obj.PrebuiltEntryCount = double(artifact.entry_count);
            end
            if obj.PrebuiltBytes > obj.MemoryLimitBytes
                error('stage8_k2_tecs_cache_session:MemoryBound', ...
                    'MEMORY_BOUND_FAIL: prebuilt cache exceeds 512 MiB.');
            end
        end

        function bytes = bucket_bytes_local(obj)
            bytes = 0;
            names = keys(obj.Buckets);
            for index = 1:numel(names)
                entry = obj.Buckets(names{index});
                bytes = bytes + double(entry.accounted_bytes) + ...
                    numel(names{index}) * 2;
            end
        end

        function update_peak_local(obj, copy_bytes)
            obj.BytesPeak = max(obj.BytesPeak, ...
                obj.BytesCurrent + double(copy_bytes));
            obj.enforce_memory_local();
        end

        function enforce_memory_local(obj)
            if obj.BytesPeak > obj.MemoryLimitBytes
                error('stage8_k2_tecs_cache_session:MemoryBound', ...
                    'MEMORY_BOUND_FAIL: session exceeds 512 MiB.');
            end
        end

        function reject_truth_local(obj, value)
            if contains_truth_local(value)
                obj.TruthLeakageCount = obj.TruthLeakageCount + 1;
                error('stage8_k2_tecs_cache_session:TruthLeakage', ...
                    'INTEGRATED_TRUTH_LEAKAGE_STOP: truth field in cache payload.');
            end
        end
    end
end

function flag = contains_truth_local(value)
flag = false;
if isstruct(value)
    names = fieldnames(value);
    if any(contains(lower(string(names)), 'truth'))
        flag = true;
        return;
    end
    for element = 1:numel(value)
        for index = 1:numel(names)
            if contains_truth_local(value(element).(names{index}))
                flag = true;
                return;
            end
        end
    end
elseif iscell(value)
    for index = 1:numel(value)
        if contains_truth_local(value{index})
            flag = true;
            return;
        end
    end
end
end
