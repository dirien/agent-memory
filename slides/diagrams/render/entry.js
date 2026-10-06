// Mermaid -> Excalidraw -> SVG, styled for the dark Pulumi deck.
import { parseMermaidToExcalidraw } from "@excalidraw/mermaid-to-excalidraw";
import { convertToExcalidrawElements, exportToSvg, FONT_FAMILY } from "@excalidraw/excalidraw";

const C = {
  text: "#f2effb",       // labels
  stroke: "#cfc6ff",     // shape outlines
  fill: "#2c2747",       // shape fill
  arrow: "#a99bff",      // arrows
  accent: "#8f7cff",     // highlighted node outline
  accentFill: "#3d3170", // highlighted node fill
};

window.renderMermaid = async (definition, { highlight = [], fontSize = 20 } = {}) => {
  await document.fonts.load(`${fontSize}px Excalifont`);
  const { elements, files } = await parseMermaidToExcalidraw(definition, {
    themeVariables: { fontSize: `${fontSize}px`, fontFamily: "Excalifont" },
  });
  // mermaid-to-excalidraw keeps <br> literally; make it a real line break
  for (const el of elements) {
    if (el.label && typeof el.label.text === "string") el.label.text = el.label.text.replace(/<br\s*\/?>/gi, "\n");
    if (typeof el.text === "string") el.text = el.text.replace(/<br\s*\/?>/gi, "\n");
  }
  const els = convertToExcalidrawElements(elements, { regenerateIds: false });
  const hl = new Set(highlight);
  for (const el of els) {
    el.roughness = 1;
    if (el.type === "text") {
      el.strokeColor = C.text;
      el.fontFamily = FONT_FAMILY.Excalifont;
    } else if (el.type === "arrow" || el.type === "line") {
      el.strokeColor = C.arrow;
      el.strokeWidth = 2;
    } else {
      const lit = [...hl].some((h) => el.id === h || (el.boundElements || []).some(() => false));
      el.strokeColor = lit ? C.accent : C.stroke;
      el.backgroundColor = lit ? C.accentFill : C.fill;
      el.fillStyle = "solid";
      el.strokeWidth = lit ? 3 : 2;
    }
  }
  // highlight by node label: containers whose bound text matches
  if (hl.size) {
    const byId = new Map(els.map((e) => [e.id, e]));
    for (const t of els.filter((e) => e.type === "text" && e.containerId)) {
      if ([...hl].some((h) => t.text.replace(/\n/g, " ").includes(h))) {
        const box = byId.get(t.containerId);
        if (box) { box.strokeColor = C.accent; box.backgroundColor = C.accentFill; box.strokeWidth = 3; }
      }
    }
  }
  // Mermaid sizes boxes with almost no padding; Excalifont text then touches the
  // edges. Grow any box that is tighter than its text plus padding, around its
  // centre, so the text stays centred and arrows still meet the edge.
  {
    const PAD_X = 22, PAD_Y = 14;
    const byId2 = new Map(els.map((e) => [e.id, e]));
    for (const t of els.filter((e) => e.type === "text" && e.containerId)) {
      const box = byId2.get(t.containerId);
      if (!box || box.type === "arrow") continue;
      const needW = t.width + 2 * PAD_X, needH = t.height + 2 * PAD_Y;
      if (box.width < needW) { box.x -= (needW - box.width) / 2; box.width = needW; }
      if (box.height < needH) { box.y -= (needH - box.height) / 2; box.height = needH; }
    }
  }
  const svg = await exportToSvg({
    elements: els,
    files,
    appState: { exportBackground: false, viewBackgroundColor: "transparent", exportWithDarkMode: false, exportPadding: 16 },
    exportPadding: 16,
  });
  return svg.outerHTML;
};
window.ready = true;
