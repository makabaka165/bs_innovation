# Symbol -> Code Variable -> Dimension / Unit Mapping

This table records the second-round symbol audit. It is deliberately conservative: if a symbol is conceptually correct but not fully harmonized across paper and code, the status is `Risk`.

| Symbol | Meaning | Paper dimension / unit | Code variable / source | Code dimension / unit | Status | Audit note |
|---|---|---|---|---|---|---|
| `f_c` | Carrier frequency | scalar, Hz | `cfg.arr.fc` in `sim_cfg.m` | `10e9` Hz | Pass | Matches parameter table. |
| `c` | Light speed | scalar, m/s | `cfg.arr.c` | `3e8` m/s | Pass | Matches parameter table. |
| `lambda` | Wavelength | scalar, m | `cfg.arr.lambda=cfg.arr.c/cfg.arr.fc` | `0.03` m | Pass | Used by steering and cache code. |
| `N_az` | Full cylinder azimuth columns | scalar count | `cfg.arr.Naz` | `192` | Pass | Full-array count, not working-subarray count. |
| `N_el` | Full cylinder elevation layers | scalar count | `cfg.arr.Nel` | `32` | Pass | Full-array count. |
| `M_all` | Full array elements | scalar count | `cfg.arr.Naz*cfg.arr.Nel` | `6144` | Pass | Should not be confused with working-subarray `M`. |
| `M` | Working-subarray element count | scalar count | `cfg.beam.subNaz*cfg.arr.Nel`, `size(W,1)` | `65*32=2080` | Pass | Current manuscript uses beamspace W as `2080 x 7`; keep `M` scoped to working subarray. |
| `p_m` | m-th element position | `3 x 1`, m | `x`, `y`, `z`, `geom.x_canonical` etc. | vector entries in meters | Pass | Code uses separate coordinate vectors. |
| `u(az,el)` | Direction unit vector | `3 x 1` | `ux=cosd(el)*cosd(az)`, `uy=cosd(el)*sind(az)`, `uz=sind(el)` | scalar components | Pass | Matches standard az/el direction convention. |
| `a_cyl(az,el)` | Cylindrical steering vector | `M x 1` | `build_cyl_steering_vec` output `a` | `numel(x) x 1` | Risk | Code computes `exp(1j*phase_sign*phase_factor*2*pi/lambda*p^T u)`. Manuscript formula omits `phase_factor`; default config uses `phase_factor=2`. |
| `A_cyl(Theta)` | Two-target manifold | `M x 2` | `A_pair=[a1,a2]` in pair manifold functions | `N_elem x 2` | Pass | Shape check exists in code. |
| `Y` | Element-domain observation | `M x L` | `validation.Y`, `Y_work` | `size(W,1) x L` | Pass | Step11.7 validates `Y` before `Z=context.W'*validation.Y`. |
| `W` | Beamspace transform | `M x B` | `W`, `context.W` | `2080 x 7` for recommended route | Pass | Code uses `size(W,1)=N_elements`, `size(W,2)=B`; projection is `W'Y`. |
| `Z` | Beamspace observation | `B x L` | `Z=context.W'*validation.Y` | `B x L` | Pass | Confirmed in Step11.7 direct and cached backends. |
| `G(Theta)` | Beamspace manifold | `B x 2` | `G`, `G_grid`, `cache.G_grid` slices | `B x 2` for candidates; cache is `B x N_delta x N_el` | Pass | Candidate scoring uses beamspace manifold. |
| `P_G` | DML projection matrix | `B x B` | `P=G/(G'*G+reg*I)*G'` | `B x B` | Pass | Code uses regularization `reg=1e-10` by default. |
| `J(Theta)` | DML score | scalar | `score=real(trace(P*(Z*Z')))` | scalar | Pass | Formula-code match for regularized projection score. |
| `Theta` | Two-target candidate parameters | varies by model | candidate structs / grid indices | common-el, pair2d, or full4D dependent | Pass | Manuscript correctly separates model roles. |
| `az_c`, `el_c` | Local center angles | scalar, degrees | `az_center_true`, `el_center_nominal`, coarse centers | degrees | Pass | Scope is local backend window, not full-space blind search. |
| `Delta_az` | Azimuth separation | scalar, degrees | `az_sep_deg` | degrees | Pass | Used in scenario and search grids. |
| `Delta_el` | Elevation separation | scalar, degrees | `el_sep_deg`, `el_sep_deg_list` | degrees | Pass | `0` degenerates to common-el. |
| `q` | Pair2d orientation | `+1` or `-1` | `orientation`, `search_orientations` | `+1/-1` | Pass | For `q=+1`, `el1=center-sep/2`, `el2=center+sep/2`; for `q=-1`, reversed. |
| `B` | Beamspace dimension / beam count | scalar count | `w_info.B`, `context_metadata.B` | recommended `7` | Pass | `greedy_combined_B7` is supported by Step11.2. |
| `K` | Fixed coarse topK | scalar count | `recommended_topK`, `cfg.topK` | `3` | Pass | Step11.3 fixed topK3. |
| `K_max` | C05 topK upper bound | scalar count | `policy_cfg.topK_max` | `7` | Pass | Confirmed in policy defaults and manuscript parameter list. |
| `H_norm` | Normalized score entropy | scalar in `[0,1]` | `features.H_norm` | scalar | Pass | Used as one likelihood-landscape cue. |
| `gap_13`, `gap_17` | Score gap cues | scalar | `features.gap_13`, `features.gap_17` | scalar | Pass | Used by C05 ambiguity / easy policy. |
| `U_search` | Search budget uncertainty | scalar in `[0,1]` | `features.U_search`, `policy.U_search` | scalar | Pass | Code formula: weighted combination of gap risk, boundary risk, and entropy cue. |
| `U_confidence` | Confidence uncertainty | scalar in `[0,1]` | `features.U_confidence`, `policy.U_confidence` | scalar | Pass | Code formula includes entropy, gap risk, conditioning risk, and boundary risk. |
| `boundary_risk` | Boundary indicator | scalar flag | `features.boundary_risk` | `0/1` | Pass | Boundary branch is the only policy branch that expands refine window. |
| `cond_risk` | Conditioning risk | scalar flag/risk | `features.cond_risk` | scalar | Pass | Drives `ILL_CONDITIONED` policy when over threshold. |
| `G_cache(delta_az,el)` | Canonical cache entry | cached beamspace manifold | `cache.G_grid(:,iAz,iEl)` | `B x 1` per single steering vector grid entry | Pass | Pair candidates combine cached single-target columns; lookup is exact-grid only. |
| `rho` | Target coherence | scalar | `rho` in scenario CSVs | unitless | Pass | Boundary statements should remain scoped to tested coherence cases. |
| `Metkl` | Monte Carlo count | scalar count | `cfg_eval.Metkl`, recheck configs | common `10`, supplementary `30` | Pass | Supplementary Metkl=30 totals 450 trials in Stage11.5 recheck. |

## Symbol Risks To Fix

| Risk | Required action |
|---|---|
| Steering-vector phase factor mismatch | Either include `phase_factor=2` in the paper formula for the double-path model, or explicitly define the paper formula as a normalized one-way steering convention and state that experiments use the double-path factor. |
| `M` ambiguity | Keep `M` as working-subarray element count in backend formulas; use a distinct symbol such as `M_all` for the full 6144-element array if both appear nearby. |
| `G_cache` dimension wording | Avoid describing the persistent cache as directly `B x 2`; the persistent table stores single-target beamspace manifold columns over canonical `(delta_az, el)` grid and pair candidates assemble two columns. |
