const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const baseDir = __dirname;
const mdPath = path.join(baseDir, '圆柱阵波束级ML测角小论文初稿.md');
const outDir = path.join(baseDir, 'output');
const htmlPath = path.join(outDir, '圆柱阵波束级ML测角小论文初稿.html');
const pdfPath = path.join(outDir, '圆柱阵波束级ML测角小论文初稿.pdf');
const chromePath = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

(async () => {
const { marked } = await import('file:///C:/Users/makab/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js');

fs.mkdirSync(outDir, { recursive: true });

let md = fs.readFileSync(mdPath, 'utf8');

const mathBlocks = [];
const inlineMath = [];

md = md.replace(/\$\$[\s\S]*?\$\$/g, (m) => {
  const id = mathBlocks.length;
  mathBlocks.push(m);
  return `\n\n@@MATH_BLOCK_${id}@@\n\n`;
});

md = md.replace(/\\\([\s\S]*?\\\)/g, (m) => {
  const id = inlineMath.length;
  inlineMath.push(m);
  return `@@INLINE_MATH_${id}@@`;
});

md = md.replace(/\$(?!\$)([^$\n]+?)\$/g, (m) => {
  const id = inlineMath.length;
  inlineMath.push(m);
  return `@@INLINE_MATH_${id}@@`;
});

function renderFigure(alt, src, attrs = '') {
  let style = '';
  const width = attrs.match(/width=([0-9.]+)%/);
  const height = attrs.match(/height=([0-9.]+)cm/);
  if (width) style += `max-width:${width[1]}%;`;
  if (height) style += `max-height:${height[1]}cm;`;
  const safeAlt = alt.replace(/"/g, '&quot;');
  return `<figure class="figure"><img src="${src}" alt="${safeAlt}" style="${style}"><figcaption>${safeAlt}</figcaption></figure>`;
}

// Pandoc-style image attributes are not understood by marked. Convert the few
// attributes used in the manuscript into inline HTML sizing and visible captions.
md = md.replace(/!\[([^\]]*)\]\(([^)]+)\)\{([^}]+)\}/g, (_m, alt, src, attrs) => {
  return renderFigure(alt, src, attrs);
});

md = md.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, (_m, alt, src) => {
  return renderFigure(alt, src);
});

marked.setOptions({
  gfm: true,
  breaks: false
});

let body = marked.parse(md);

body = body.replace(/<p>@@MATH_BLOCK_(\d+)@@<\/p>/g, (_m, id) => {
  return `<div class="math-block">${mathBlocks[Number(id)]}</div>`;
});
body = body.replace(/@@MATH_BLOCK_(\d+)@@/g, (_m, id) => mathBlocks[Number(id)]);
body = body.replace(/@@INLINE_MATH_(\d+)@@/g, (_m, id) => inlineMath[Number(id)]);

// Resolve relative image paths after Markdown conversion.
body = body.replace(/<img([^>]+)src="([^":]+)"/g, (_m, pre, src) => {
  const abs = path.resolve(baseDir, src).replace(/\\/g, '/');
  return `<img${pre}src="file:///${abs}"`;
});

const html = `<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>圆柱阵波束级ML测角小论文初稿</title>
<script>
window.MathJax = {
  tex: {
    inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
    displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']],
    tags: 'ams'
  },
  svg: { fontCache: 'global' },
  startup: {
    ready: () => {
      MathJax.startup.defaultReady();
      MathJax.startup.promise.then(() => { window.mathjaxDone = true; });
    }
  }
};
</script>
<script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
<style>
@page {
  size: A4;
  margin: 22mm 20mm 24mm 20mm;
}
html {
  color: #111;
  font-family: "Times New Roman", "SimSun", "宋体", serif;
  font-size: 10.8pt;
  line-height: 1.62;
}
body {
  margin: 0 auto;
  max-width: 168mm;
}
h1, h2, h3 {
  font-family: "Times New Roman", "SimHei", "黑体", sans-serif;
  font-weight: 700;
  line-height: 1.35;
  page-break-after: avoid;
}
h1 {
  text-align: center;
  font-size: 18pt;
  margin: 0 0 15pt;
}
h2 {
  text-align: left;
  font-size: 14pt;
  margin: 18pt 0 8pt;
  border-bottom: 0.5pt solid #999;
  padding-bottom: 2pt;
}
h3 {
  text-align: left;
  font-size: 12pt;
  margin: 14pt 0 6pt;
}
p {
  margin: 0 0 7pt;
  text-align: justify;
  text-indent: 2em;
}
.figure {
  text-indent: 0;
  text-align: center;
  margin: 9pt 0 11pt;
  page-break-inside: avoid;
}
.figure img {
  display: block;
  margin: 0 auto 4pt;
}
figcaption {
  font-size: 9.5pt;
  line-height: 1.45;
  text-align: center;
  color: #222;
}
img {
  display: block;
  margin: 0 auto;
  max-width: 100%;
  height: auto;
  object-fit: contain;
}
table {
  border-collapse: collapse;
  margin: 8pt auto 11pt;
  width: 96%;
  font-size: 9.4pt;
  page-break-inside: avoid;
}
th, td {
  border: 0.5pt solid #777;
  padding: 3pt 5pt;
}
th {
  background: #f2f2f2;
  font-weight: 700;
}
pre, code {
  font-family: Consolas, "Courier New", monospace;
  font-size: 9.4pt;
}
pre {
  white-space: pre-wrap;
  background: #f6f6f6;
  border: 0.5pt solid #ccc;
  padding: 7pt;
}
.mjx-container[jax="SVG"][display="true"] {
  margin: 0.55em 0 !important;
  max-width: 100% !important;
  overflow: visible !important;
  font-size: 94% !important;
}
.mjx-container[jax="SVG"]:not([display="true"]) {
  font-size: 96% !important;
}
.math-block {
  text-align: center;
  margin: 6pt 0 8pt;
  text-indent: 0;
}
strong {
  font-weight: 700;
}
a {
  color: inherit;
  text-decoration: none;
}
</style>
</head>
<body>
${body}
</body>
</html>`;

fs.writeFileSync(htmlPath, html, 'utf8');

execFileSync(chromePath, [
  '--headless=new',
  '--disable-gpu',
  '--no-sandbox',
  '--no-pdf-header-footer',
  '--allow-file-access-from-files',
  '--run-all-compositor-stages-before-draw',
  '--virtual-time-budget=15000',
  `--print-to-pdf=${pdfPath}`,
  htmlPath
], { stdio: 'inherit' });

console.log(pdfPath);
})().catch((err) => {
  console.error(err.stack || err.message);
  process.exit(1);
});
