function [B, L, K] = validate_dml_inputs(Z, G, caller_name)
%VALIDATE_DML_INPUTS Validate common stable-score matrix contracts.

if ~(isnumeric(Z) && ismatrix(Z) && all(isfinite(Z(:))) && ...
        (isa(Z, 'double') || isa(Z, 'single')))
    error([caller_name ':Data'], ...
        'Z must be a finite single- or double-precision matrix.');
end
if ~(isnumeric(G) && ismatrix(G) && all(isfinite(G(:))) && ...
        (isa(G, 'double') || isa(G, 'single')))
    error([caller_name ':Manifold'], ...
        'G must be a finite single- or double-precision matrix.');
end
[B, L] = size(Z);
K = size(G, 2);
if B < 1 || L < 1 || K < 1
    error([caller_name ':EmptyDimension'], ...
        'Z and G must have positive beam, snapshot, and manifold dimensions.');
end
if size(G, 1) ~= B
    error([caller_name ':BeamDimension'], ...
        'Z and G must have the same number of rows.');
end
if ~strcmp(class(Z), class(G))
    error([caller_name ':PrecisionMismatch'], ...
        'Z and G must use the same floating-point precision.');
end
end
