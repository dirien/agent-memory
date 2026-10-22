// node render.mjs [--font N] [--grid] <in.mmd> <out.svg> [highlight label ...]
import { chromium } from "playwright";
import { readFileSync, writeFileSync } from "node:fs";
const args = process.argv.slice(2);
const fi = args.indexOf("--font"); const fontSize = fi >= 0 ? Number(args.splice(fi, 2)[1]) : 20;
const gi = args.indexOf("--grid"); const grid = gi >= 0 && args.splice(gi, 1).length > 0;
const [input, output, ...highlight] = args;
const browser = await chromium.launch();
const page = await browser.newPage();
page.on("console", (m) => { if (m.type() === "error") console.error("page:", m.text()); });
await page.goto("http://127.0.0.1:8765/page.html");
await page.waitForFunction(() => window.ready === true);
const svg = await page.evaluate(([d, h, f, g]) => window.renderMermaid(d, { highlight: h, fontSize: f, grid: g }), [readFileSync(input, "utf8"), highlight, fontSize, grid]);
writeFileSync(output, svg);
await browser.close();
console.log(`${output}: ${svg.length} bytes`);
