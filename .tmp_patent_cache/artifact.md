# Canonical Beamspace Manifold Cache Patent Artifact Contract

## Design authority

- Primary reference: `E:\bs_innovation\zhuanli\一种二维平面阵列差分共阵孔径扩展方法-初稿(1).docx`.
- Secondary reference: `E:\bs_innovation\zhuanli\一种二维差分共阵虚拟阵元冗余度降重与后验判定方法-初稿(1).docx`.
- Preserve the reference patents' five-part order: 说明书摘要、摘要附图、权利要求书、说明书、说明书附图.
- Start every part on a new Word section and restart displayed page numbering at 1.

## Page and typography

- A4 portrait.
- Margins: left 0.98 in, right 0.79 in, top 0.98 in, bottom 0.59 in.
- Chinese body font: 方正楷体_GB2312; western font: Times New Roman; body size: 12 pt.
- Body paragraphs: justified, first-line indent 24 pt, approximately 18 pt fixed line spacing.
- Major part titles: centered, 18 pt, spaced Chinese characters, with a horizontal rule below.
- Patent subsection headings use the same compact centered/left-aligned hierarchy found in the primary reference.
- Enable line numbering at intervals of five lines when supported by Word.

## Content scope

- Sole inventive subject: a shared-center canonical beamspace manifold cache for a cylindrical array.
- Include: center snapping, canonical element order, rotational equivalence, offline exact-grid union, cache tensor, cache identity metadata, global-to-local azimuth conversion, exact lookup, miss recording and direct-construction fallback.
- Exclude: C05, top-K selection, full-4D search, tangent approximation and every unrelated estimation/search algorithm.
- `spatialPhaseFactor=2` is only a historical embodiment parameter used by the saved Step11.6 evidence. It is not a defining algorithm step and is not a limitation of the independent claims.
- Do not claim interpolation; the verified implementation uses exact-grid lookup.

## Terminology

- 圆柱阵（Cylindrical Array，CA）.
- 波束域（Beamspace，BS）.
- 规范波束域流形缓存（Canonical Beamspace Manifold Cache，CBMC）.
- 共享中心（Shared Center，SC）.
- 精确网格查表（Exact-Grid Lookup，EGL）.
- 到达角（Direction of Arrival，DOA），only when needed.
- On first and material repeated uses, write the Chinese name first, followed by the full English name and abbreviation in parentheses.

## Equations

- Markdown equations use standard `$...$` and `$$...$$` LaTeX delimiters.
- Word equations remain centered literal LaTeX text, not OMML, so they can be converted later with MathType.
- Equation numbers use right-aligned Chinese full-width parentheses, e.g. `（1）`.

## Figures

- Black-and-white patent drawing style, white background, rectangular process boxes, solid black arrows, restrained line weights, no decorative color.
- Figure 1: method flow S101-S106.
- Figure 2: cylindrical-array shared-center rotational equivalence.
- Figure 3: offline cache tensor construction and online exact lookup.
- Figure 4: saved code-run results limited to cache evidence (equivalence error, cross-center pass, build time, memory and miss count).
- Caption form: `图 1` etc.; explain every reference numeral in 附图说明 and 具体实施方式.

## Verified evidence source

- Source directory: `E:\bs_innovation\beamspace_ml_v18\source\stepwise_signal_model\steps\step_11_6_shared_center_rotatable_beamspace_manifold_cache`.
- Saved Step11.6 evidence: B=7, 2080 elements, 112 delta-azimuth nodes, 174 elevation nodes, 2.081543 MB, 0.937862 s build time, max relative steering error 3.82e-14, max relative beamspace-manifold error 3.23e-14, max relative score difference 8.3e-16, zero cache misses, six of six tested centers passed.
- Keep measured runtime reduction only as an optional embodiment effect; do not present unrelated search logic.

## Deliverables and QA

- Synchronized final Markdown and DOCX under `E:\bs_innovation\zhuanli`.
- DOCX is rendered through Microsoft Word to PDF and every page is rasterized and inspected.
- Audit headings, section breaks, page-number restarts, images, fonts and literal LaTeX preservation before delivery.
