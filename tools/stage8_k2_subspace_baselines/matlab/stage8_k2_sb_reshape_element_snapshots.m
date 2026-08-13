function cube = stage8_k2_sb_reshape_element_snapshots(Y_element, N_el, N_az)
%STAGE8_K2_SB_RESHAPE_ELEMENT_SNAPSHOTS Map canonical vectors to Nel x Naz x L.

if nargin < 3
    constants = stage8_k2_sb_constants();
    N_el = constants.N_el;
    N_az = constants.N_az;
end
if ~(isnumeric(Y_element) && ismatrix(Y_element) && ...
        size(Y_element, 1) == N_el * N_az && ...
        all(isfinite(Y_element(:))))
    error('stage8_k2_sb_reshape_element_snapshots:Data', ...
        'Element data must be finite canonical (Nel*Naz)-by-L data.');
end
cube = reshape(Y_element, N_el, N_az, size(Y_element, 2));
end
