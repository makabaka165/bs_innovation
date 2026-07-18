function audit = audit_stage7_sequential_channel_semantics(V, Uset, Y)
%AUDIT_STAGE7_SEQUENTIAL_CHANNEL_SEMANTICS Verify the two-stage channel map.

if ~(isnumeric(V) && ismatrix(V) && ~isempty(V) && ...
        isnumeric(Uset) && ndims(Uset) == 3 && ~isempty(Uset) && ...
        isnumeric(Y) && ismatrix(Y) && ~isempty(Y))
    error('audit_stage7_sequential_channel_semantics:Inputs', ...
        'V, Uset, and Y must be nonempty numeric arrays.');
end
N_el = size(Y, 1);
N_az = size(Y, 2);
B_el = size(V, 2);
B_az = size(Uset, 2);
if size(V, 1) ~= N_el || size(Uset, 1) ~= N_az || ...
        size(Uset, 3) ~= B_el
    error('audit_stage7_sequential_channel_semantics:Dimensions', ...
        'Expected V=[N_el,B_el], Uset=[N_az,B_az,B_el], Y=[N_el,N_az].');
end

Zel = V' * Y;
Zseq = complex(zeros(B_el, B_az));
W = complex(zeros(N_el * N_az, B_el * B_az));
channel_error = zeros(B_el, B_az);
for c = 1:B_az
    for b = 1:B_el
        column = b + (c - 1) * B_el;
        u = Uset(:, c, b);
        v = V(:, b);
        Zseq(b, c) = u' * Zel(b, :).';
        W(:, column) = kron(u, v);
        direct = W(:, column)' * Y(:);
        channel_error(b, c) = abs(Zseq(b, c) - direct) / ...
            max(abs(direct), realmin);
    end
end
equivalent = reshape(W' * Y(:), B_el, B_az);
equivalence_error = norm(Zseq - equivalent, 'fro') / ...
    max(norm(equivalent, 'fro'), realmin);

if B_el == 3 && B_az == 5
    terminology = "3 个俯仰中间通道，每通道 5 个条件方位输出";
else
    terminology = sprintf('%d elevation intermediate channels, each with %d conditioned azimuth outputs', ...
        B_el, B_az);
end
audit = struct();
audit.B_el = B_el;
audit.B_az = B_az;
audit.B_out = B_el * B_az;
audit.Zel_dimension = [B_el, N_az];
audit.Zseq_dimension = [B_el, B_az];
audit.processing_order = ...
    'ELEVATION_DBF_THEN_ELEVATION_CONDITIONED_AZIMUTH_DBF';
audit.first_stage_fixed_object = ...
    'V is fixed and Zel=V''*Y preserves all N_az columns';
audit.second_stage_conditioned_object = ...
    'u(c|b) is conditioned on elevation intermediate channel b';
audit.equivalent_weight_formula = 'w(b,c)=kron(u(c|b),v(b))';
audit.terminology_status = terminology;
audit.Zel_formula = 'Zel=V''*Y';
audit.conditioned_output_formula = 'z(b,c)=u(c|b)''*Zel(b,:)''';
audit.B_out_formula = 'B_out=B_el*B_az';
audit.channel_order = 'elevation_channel_fastest_then_azimuth_output';
audit.equivalence_relative_error = equivalence_error;
audit.maximum_channel_relative_error = max(channel_error, [], 'all');
audit.Zel = Zel;
audit.Zseq = Zseq;
audit.W_equivalent = W;
end
