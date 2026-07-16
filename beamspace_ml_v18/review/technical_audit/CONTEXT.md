# Beamspace ML Paper Audit Context

This context defines the review language for the beamspace ML paper audit. It is a glossary only: implementation paths, experiment numbers, and revision decisions belong in audit outputs, not here.

## Language

**Local Unresolved Two-Target Backend**:
A backend estimator that operates after a front-end has provided a local candidate region containing two closely spaced targets.
_Avoid_: full radar closed loop, blind all-space search

**Element-Domain Observation**:
The array observation before beamspace projection, indexed by physical array elements and snapshots.
_Avoid_: beam-domain data

**Beamspace Observation**:
The low-dimensional observation after applying the beamspace transform to the element-domain observation.
_Avoid_: beam index only representation

**Cylindrical-Array Manifold**:
The steering-vector model determined by the physical cylindrical array geometry and target direction.
_Avoid_: empirical beam smoothing model

**Controlled Pair2D**:
The paper's main local two-target parameterization using a center, azimuth separation, elevation separation, and a finite orientation variable.
_Avoid_: full4D, common-el

**Common-El Baseline**:
A restricted comparison model where the two targets share the same elevation.
_Avoid_: main method

**Local Full4D Upper-Bound Reference**:
A local reference search where both target angles vary independently, used to bound model expressiveness and cost in the recorded setting.
_Avoid_: default engineering algorithm

**Beamspace Transform**:
The matrix that maps the element-domain observation and manifold into beamspace.
_Avoid_: W selection result

**DML Score**:
The deterministic maximum-likelihood objective based on projecting the beamspace observation onto a candidate beamspace manifold.
_Avoid_: MUSIC spectrum

**Fixed TopK3 Coarse-To-Fine Search**:
A two-stage search that first keeps three coarse candidates and then refines locally around them.
_Avoid_: adaptive C05

**C05 Adaptive Budget**:
A search-budget policy that adjusts top-K and local-window size from likelihood-landscape cues while preserving the same estimator and scoring criterion.
_Avoid_: new likelihood score

**Likelihood-Landscape Cue**:
A scalar or categorical signal derived from the local score landscape to indicate ambiguity, boundary risk, or conditioning risk.
_Avoid_: estimator output

**Shared-Center Canonical Cache**:
A reusable beamspace manifold cache based on a canonical local coordinate system for shared-center cylindrical-array geometry.
_Avoid_: interpolating cache

**Exact-Grid Lookup**:
A cache lookup that succeeds only when the requested grid point exists in the precomputed cache.
_Avoid_: interpolation, extrapolation

**Representative Case Figure**:
A figure used to explain behavior on selected examples rather than to establish a statistical claim.
_Avoid_: main statistical evidence
