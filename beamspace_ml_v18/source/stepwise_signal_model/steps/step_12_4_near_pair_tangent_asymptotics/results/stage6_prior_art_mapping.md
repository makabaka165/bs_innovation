# Stage-6 Prior-Art Incremental Mapping

> Access date: 2026-07-17
> Scope: bounded formula-targeted retrieval, not an exhaustive patent or full-text search.

## Claim mapping

| Item | Label | Boundary |
|---|---|---|
| Center-difference parameterization | Mathematical form similar | Standard close-source symmetric localization. |
| Sum-difference unitary transform | Existing identical linear-algebra mechanism | A two-column Hadamard/unitary change of basis is standard. |
| Projected Jacobian metric | Existing identical method | It is the geometric part of the deterministic effective FIM after eliminating complex amplitude. |
| Second-singular-value quadratic asymptotic | Mathematical form similar | Close-source CRB and manifold geometry provide the local tangent basis; no direct fixed sequential-DBF equation was located in the bounded search. |
| Normalized-coherence quadratic deficit | Mathematical form similar | Normalized manifold distance/coherence uses the same projected tangent metric. |
| Normalized-Gram condition asymptotic | Mathematical form similar | The exact two-column Gram spectrum is standard; the current use is a sequential-manifold specialization. |
| Exact-null third-order effective vector and sixth-order candidate | No direct identical equation located | Validated here on an analytic fixture; no registered primary physical exact null was found. |
| Unified use on a fixed whitened sequential cylindrical manifold | No direct identical complete treatment located | This is reported only as a scenario-specific corollary, not proof of novelty. |

## Directly checked works

- *Differential Geometry of Array Manifold Surfaces* (2004), DOI 10.1142/9781860946028_0003.
- *Statistical Angular Resolution Limit for Point Sources* (2007), DOI 10.1109/TSP.2007.898789.
- Vincent, Besson and Chaumette, *Approximate maximum likelihood estimation of two closely spaced sources* (2014), DOI 10.1016/j.sigpro.2013.10.017.
- *On Fisher Information Matrix, Array Manifold Geometry and Time Delay Estimation* (2023), DOI 10.1007/978-3-031-38271-0_30.
- Lee and Wengrovitz, *Resolution threshold of beamspace MUSIC for two closely spaced emitters* (1990), DOI 10.1109/29.60074.

## Reproducible retrieval provenance

- OpenAlex: `GET /works?search={query}&per_page=5&select=id,doi,title,publication_year,cited_by_count` for the five locked formula queries. Counts were 2933, 12360, 368, 2499 and 496; leading results were mostly off-topic, so counts were not used as evidence.
- Crossref: `GET /works?query.bibliographic={query}&rows=5` for the same five queries, plus exact `GET /works/{doi}` calls for the five works above.
- Semantic Scholar: `GET /graph/v1/paper/search?query={query}&limit=8&fields=...`; all five calls returned HTTP 429 without an API key. The failure is recorded and is not interpreted as an empty literature set.
- Search phrases: second singular value of two steering vectors Taylor expansion; projected Jacobian close sources singular value; normalized coherence local Fisher metric; Gram condition number closely spaced array manifold; tangent-null higher-order array manifold separation.

## Conclusion

No directly identical publication containing all three asymptotic equations and the exact-null extension on the present fixed whitened sequential cylindrical receive manifold was located in this bounded retrieval. This does not establish novelty. The status remains `SCENARIO_SPECIFIC_COROLLARY_PRIOR_ART_BOUNDED`.
