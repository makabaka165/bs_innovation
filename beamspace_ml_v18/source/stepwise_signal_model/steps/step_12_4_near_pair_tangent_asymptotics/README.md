# Step12.4 Fixed-Whitening Near-Pair Tangent Asymptotics

This step validates deterministic local geometry on the fixed, factor-1,
fully sequential receive manifold

\[
g(\phi,\theta)=T_{\rm seq}W_{\rm seq}^{H}a_{\rm receive}(\phi,\theta).
\]

`Wseq`, `Cseq=Wseq'*Rn_elem*Wseq`, `Tseq`, the whitening rank and all
measurement identities remain fixed inside each registered configuration.
The candidate angle changes only the receive manifold. This step does not
select beams, estimate model order, run bootstrap, tune an earlier stage, or
implement FIM beam design.

## Theory contract

For a center `c`, real separation vector `d`, projected Jacobian metric

\[
T_{\rm seq}(\mathbf c)=
\operatorname{Re}\{J_g^H\Pi_g^\perp J_g\},
\]

and nondegenerate direction
`d'*Tseq(c)*d > 0`, the registered relations are

\[
\sigma_2^2(G_2)=\frac12\mathbf d^TT_{\rm seq}\mathbf d
+o(\|\mathbf d\|^2),
\]

\[
1-|\rho|^2=
\frac{\mathbf d^TT_{\rm seq}\mathbf d}{\|g(\mathbf c)\|_2^2}
+o(\|\mathbf d\|^2),
\]

and

\[
\kappa(\bar G_2^H\bar G_2)\sim
\frac{4\|g(\mathbf c)\|_2^2}{\mathbf d^TT_{\rm seq}\mathbf d}.
\]

The projected metric is the classical deterministic effective-FIM geometry
after eliminating an unknown complex amplitude. The retained claim is only
the explicit unification of these relations for the fixed, exactly whitened,
sequential cylindrical receive manifold. Center-difference coordinates,
unitary sum-difference transforms, projected Jacobians, two-column Gram
spectra and coherence geometry are prior art.

An exact tangent-null direction is outside the nondegenerate relations. The
registered sixth-order candidate uses the effective third directional
derivative and remains separately classified from physical measurement
collapse. Deterministic manifold geometry is not a finite-sample resolution,
model-order or threshold-SNR result.

## Fixed execution contract

- The receive spatial phase is `phase_factor=1`.
- The stage-5 baseline must be an ancestor of runtime `HEAD`; equality is not
  required.
- Formal evidence execution starts only from an empty
  `git status --porcelain=v1 --untracked-files=all` result.
- Controls, physical measurement plan, experiment plan, executable source,
  direct dependencies and runtime diagnostics have separate identities.
- Candidate search never changes `Wseq`, `Cseq`, `Tseq` or whitening rank.
- Generated evidence is outside the executable source-tree identity.

## Evidence and provenance

The executable source and direct dependencies are identified by sorted Git
mode/blob/path manifests. The stage-5 baseline must be an ancestor of runtime
HEAD, and formal evidence execution must start from a clean working tree.

Stable execution identity and the current evidence status are recorded in:

- `results/stage6_provenance_contract.csv`
- `results/stage6_source_manifest.csv`
- `results/stage6_dependency_manifest.csv`
- `results/stage6_reproduction_comparison.csv`
- `results/stage6_evidence_manifest.csv`
- `results/stage6_self_reproduction_check.csv`

Run-specific HEAD, wall-clock time and process memory are isolated in:

- `results/stage6_runtime_diagnostics.csv`

This README defines the invariant execution contract. It intentionally
contains no run-specific commit, runtime, source-tree hash, provenance hash
or evidence-bundle hash.

## Reproduction

From the repository root:

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/run_step12_4_tangent_asymptotics_validation.m')
```

The core runner produces the registered deterministic CSV/Markdown evidence,
runtime diagnostics and diagnostic figures. Final-freeze tools separately
compare historical evidence, create the raw-file SHA-256 manifest, calculate
the deterministic evidence bundle identity and verify two independent clean
run snapshots.

The next phase, exact-subset FIM beam design, is not implemented here and
requires separate authorization.
