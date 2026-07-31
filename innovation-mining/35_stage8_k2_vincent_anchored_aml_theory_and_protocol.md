# Stage8 K2 Vincent Anchored Projector AML Theory and Protocol

Protocol: STAGE8_K2_VINCENT_ANCHORED_PROJECTOR_AML_V1

Authorization: AUTHORIZE_STAGE8_K2_VINCENT_ANCHORED_PROJECTOR_AML_V1

Execution branch: experiment/stage8-k2-vincent-anchored-aml-v1

Exact base: experiment/stage8-k2-classical-baselines-v1 at
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b.

## 1. Question and boundary

This isolated known-K=2 experiment tests whether a Vincent/Bonacci-inspired
anchor--separation parameterization can reduce the existing local
two-dimensional cylindrical-array curve to one data-driven anchor coordinate,
while conditionally profiling a close positive separation analytically.

The new candidate never changes Step12.7, Core-Lite, Core-Plus, the original
Tangent-Profile implementation, the classical baselines, the selected
measurement, the exact sequential whitening, the local angular domain, or any
upstream branch. It is not a two-dimensional alpha/rho grid, a new Full4D
budget, an automatic-K method, a bootstrap, or a production-interface change.

The only online safe baseline is the frozen Core-Lite fixed-grid K2 fit. Truth,
profile identity, SNR, L, noise identity, and all post-fit metrics are absent
from fitting and selection.

## 2. Fixed sequential beamspace curve

For the fixed receive geometry and one fixed whitening transform, define

    g(phi, theta) = T_I W_I^H a(phi, theta),
    Z = T_I W_I^H Y_element,
    R_Z = Z Z^H.

For any rank-two pair G, the final score is the exact concentrated DML score

    J(G) = Re trace(P_G R_Z),
    RSS = ||Z||_F^2 - J(G).

Every final candidate is evaluated through
build_full_sequential_local_manifold and concentrated_dml_rss. The Taylor
expansion only produces the conditional separation; it is never used as the
final likelihood.

## 3. Anchor--separation parameterization

The frozen Core-Lite K1 fit gives c0. The existing projected-residual
Fisher-metric procedure gives one unoriented unit axis u, canonically oriented
with u_el > 0, or u_az >= 0 when u_el is numerically zero.

With all angular distances measured in degrees, define

    xi_1(t) = c0 + t u,
    xi_2(t,rho) = c0 + (t + rho) u,
    rho > 0.

The equivalent center displacement is alpha = t + rho/2. Thus c0 is a line
coordinate origin, not a fixed geometric midpoint. The feasible line interval
is the intersection of c0 + t u with the frozen rectangular local domain.

## 4. Cylindrical directional derivatives

At xi(t), let h_r be the r-th derivative of g(xi(t)) with respect to t in
degrees. The implementation uses the exact cylindrical phase derivatives
through third order, including the degree-to-radian factor kappa = pi/180:

    h_0 = T_I W_I^H a,
    h_1 = T_I W_I^H [kappa (j p_1) a],
    h_2 = T_I W_I^H [kappa^2 (j p_2 - p_1^2) a],
    h_3 = T_I W_I^H [kappa^3 (j p_3 - 3 p_1 p_2 - j p_1^3) a].

The element ordering is canonicalized by reshape_cyl_vector_to_matrix followed
by matrix(:), matching build_full_sequential_local_manifold exactly.

## 5. Nonsingular projector expansion

For rho not equal to zero, the pair subspace of

    [h(t), h(t+rho)]

equals that of the nonsingular basis

    B(rho) = [h_0, (h(t+rho)-h(t))/rho].

Use

    B_0 = [h_0, h_1],
    B_1 = [0, h_2/2],
    B_2 = [0, h_3/3].

After an economy SVD of B_0, a constant right transform makes C_0
orthonormal. The implementation differentiates the Gram inverse and constructs
Hermitian P_0, P_1, and P_2 such that

    P(rho) = P_0 + rho P_1 + rho^2 P_2 + O(rho^3).

An anchor is invalid when rank(B_0) is not two under the existing relative-rank
contract.

## 6. Conditional AML separation

For each anchor,

    q_j(t) = Re trace(P_j(t) R_Z),  j = 0, 1, 2,
    rho_AML(t) = -q_1(t) / (2 q_2(t)).

The raw conditional rho is valid only when all values are finite,
q_2 < -64 eps(max(1, abs(q_0))), and

    1e-3 <= rho_AML(t) <= min(t_max - t, 0.35) degrees.

No invalid rho is clamped. A rank failure, nonconcave curvature, or
out-of-contract rho returns a conditional-invalid status for that anchor.

## 7. One-dimensional exact search and safe selection

The anchor interval is [t_min, t_max - rho_min]. It is scored on exactly 65
equally spaced nodes. The best valid coarse node is refined only when both
immediate valid neighbors exist, using fminbnd with TolX=1e-4 degrees and at
most 80 function evaluations. The candidate set is the coarse best, bracket
endpoints, and fminbnd result. It is ranked only by exact full-manifold
concentrated likelihood.

The raw candidate upgrades the fixed Core-Lite K2 result only if it is valid
and its exact log likelihood is at least the fixed-grid log likelihood.
Otherwise the returned result is the fixed-grid result with
FIXED_GRID_FALLBACK. The separate frozen Tangent-Profile candidate and Full4D
baseline do not enter this selection.

## 8. Independent registry and methods

The registry has 72 fresh trials:

| Factor | Values |
|---|---|
| noise | WHITE, STAGE5_TOEPLITZ_CORRELATED |
| L | 1, 4, 8 |
| SNR dB | -6, 0, +6 |
| profile | P1, P2, P3, P4 |

Profiles, source construction, and the single-CPI single-cell scenario are
unchanged from the frozen K2 experiments. Source seeds start at 3726074000 and
noise seeds at 3726075000. L=1 uses
L1_FULLY_COHERENT_BY_CONTRACT. One generated element observation is shared by:

    M0 = CORE_LITE
    M1 = TANGENT_PROFILE_SAFE
    M2 = VINCENT_ANCHORED_PROJECTOR_AML_SAFE
    M3 = FULL4D_BEAMSPACE_CML_MULTISTART

M3 is diagnostic only and keeps the pre-registered classical-baseline budget.
The expected formal outputs are 288 method rows and 72 anchored diagnostics.

## 9. Tests and decision

Required theory tests verify fourth-order directional Taylor convergence,
third-order projector-expansion convergence, a noiseless synthetic conditional
rho fixture, and the anchor parameterization identities. A P2/L=4/SNR=0/WHITE
smoke trial verifies data-only fitting, exact full-manifold scoring, and safe
fallback before the one formal run.

The final label is RETAIN only if M2 is safe-valid on 72/72 trials, does not
lose overall median or p90 joint RMSE to M1, has at least as many paired wins
as losses, improves both P2 median joint RMSE and P2 median center error, and
uses fewer mean score and SVD calls than M3. Any other complete valid result is
NOT_RETAINED. EXPERIMENT_INVALID is reserved for registry/hash mismatch, truth
leakage, frozen-path modification, or nonfinite output without a valid fixed
fallback.

## 10. Prior-art position

Vincent, Besson, and Chaumette (2014), DOI 10.1016/j.sigpro.2013.10.017, and
Bonacci, Vincent, and Gigleux (2017), DOI 10.1049/iet-rsn.2016.0446, motivate
the conditional close-source expansion. This work claims only a
system-specific implementation: a data-driven tangent axis and moving anchor
on a fixed, exactly whitened, two-dimensional cylindrical-array sequential
beamspace curve, with exact full-manifold final scoring.

It does not claim the first close-source AML method, the first anchor/rho
parameterization, the first reduction of two-dimensional ML to one dimension,
the first Taylor extension to a nonuniform array, or the first projector
expansion.

## 11. Stop boundary

After this V1 result, no second tangent axis, perpendicular offset, 2-D anchor
grid, fourth-order projector term, third-order multiple-root rho treatment,
additional start family, multi-path fusion, automatic-K feature, bootstrap,
extra trials, or V2 work is authorized. A retained result remains a candidate
only; production integration requires a separate user authorization.
