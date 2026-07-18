# Stage 7 Prior-Art Difference

Access date: 2026-07-18. Retrieval was identifier-led and bounded.

- Chepuri and Leus, arXiv:1310.5251: minimum sensor selection under FIM constraints and greedy/convex design are prior art. Its independent-observation sensor model is not this physical sequential output subset.
- Pakrooh et al., arXiv:1504.01081 and arXiv:1505.07431: normalized FIM/eigenvalue criteria and sparse measurement selection are prior art.
- Liu et al., DOI 10.12000/JR25173: beamspace CRB retention, minimum beam count under an angular gain threshold, and greedy addition are prior art. The full 16-page publisher PDF uses a semi-unitary ULA beamformer, white noise, and an angle-dictionary subset; it does not reproduce correlated-output rewhitening or the registered two-stage rectangular physical pool. Status: `EXACT_REPRODUCTION_UNAVAILABLE`.
- OpenAlex bounded searches found no directly identical complete combination. Crossref returned no DOI record for 10.12000/JR25173; the publisher metadata and PDF were used instead.

Reproducible endpoints: `https://export.arxiv.org/api/query?id_list=...`, `https://api.openalex.org/works`, `https://api.crossref.org/works/10.12000%2FJR25173`, and `https://radars.ac.cn//cn/article/pdf/preview/10.12000/JR25173.pdf`.

The registered finite-sample Pareto gate did not pass. The result is retained only as system-design analysis of the finite correlated physical sequential subset family; no beam-selection algorithm contribution is claimed.
