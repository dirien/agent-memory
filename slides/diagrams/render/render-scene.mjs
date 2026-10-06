// node render-scene.mjs <scene.mjs> <outdir>
// Renders every exported element array of the scene module to <outdir>/<name>.svg.
import { chromium } from "playwright";
import { writeFileSync } from "node:fs";
import { resolve } from "node:path";
const [sceneFile, outDir] = process.argv.slice(2);
const scenes = await import(resolve(sceneFile));
const browser = await chromium.launch();
const page = await browser.newPage();
page.on("console", (m) => { if (m.type() === "error" && !m.text().includes("Worker")) console.error("page:", m.text()); });
await page.goto("http://127.0.0.1:8765/page.html");
await page.waitForFunction(() => window.ready === true);
for (const [name, skeleton] of Object.entries(scenes)) {
  const svg = await page.evaluate((s) => window.renderScene(s), skeleton);
  writeFileSync(`${outDir}/${name}.svg`, svg);
  console.log(`${outDir}/${name}.svg: ${svg.length} bytes`);
}
await browser.close();
