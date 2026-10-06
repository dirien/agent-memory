// node preview.mjs <in.svg> <out.png>  — the SVG on the deck's dark background
import { chromium } from "playwright";
import { readFileSync } from "node:fs";
const [, , input, output] = process.argv;
const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1600, height: 900 } });
await p.setContent(`<body style="margin:0;background:#211d2e;display:flex;align-items:center;justify-content:center;height:100vh">${readFileSync(input, "utf8").replace("<svg", '<svg style="max-width:96vw;max-height:92vh"')}</body>`);
await p.waitForTimeout(800); await p.screenshot({ path: output }); await b.close();
