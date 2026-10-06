# Deck diagrams: Mermaid in, Excalidraw out

The diagrams in `../../public/diagrams/` are written as Mermaid (`../*.mmd`) and
drawn by [`@excalidraw/mermaid-to-excalidraw`](https://github.com/excalidraw/mermaid-to-excalidraw),
restyled for the dark deck and exported with `exportToSvg`. The SVGs embed the
Excalifont subset they use, so they render offline.

Mermaid needs a DOM, so the conversion runs in headless Chromium:

```bash
npm install && npx playwright install chromium
npm run bundle                      # entry.js -> bundle.js
npm run serve &                     # page.html + Excalidraw's fonts on :8765
node render.mjs --font 24 ../curation.mmd ../../public/diagrams/curation.svg "Jev"
node render.mjs --font 28 ../architecture.mmd ../../public/diagrams/architecture.svg "Elasticsearch"
node render.mjs --font 28 ../recall.mmd ../../public/diagrams/recall.svg "Elasticsearch"
node preview.mjs ../../public/diagrams/curation.svg /tmp/curation.png   # check it on the dark background
node render-scene.mjs ../system1-vs-2.mjs ../../public/diagrams      # hand-placed scene: one SVG per export
node render-scene.mjs ../jev-shapes.mjs ../../public/diagrams
```

Trailing arguments to `render.mjs` are node labels to highlight. `page.html`
loads Excalifont so Mermaid sizes the boxes for it; `entry.js` turns `<br/>`
into real line breaks (the converter keeps them literally) and applies the
deck colours.

Layouts Mermaid can't express (the System 1 vs System 2 slide) are written as
Excalidraw element skeletons in a `.mjs` module and drawn by `render-scene.mjs`
through `window.renderScene`; text with a `cx` is centred on that x.
