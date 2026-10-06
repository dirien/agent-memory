// System 1 vs System 2, hand-placed (Mermaid can't lay this out).
// Rendered as two layers with the same frame, so the slide can reveal
// System 2 on a click: render-scene.mjs writes system1.svg and system2.svg.
const O = "#ffa94d"; // System 1 (Jev)
const B = "#4dabf7"; // System 2 (LLMs)
const W = "#f2effb"; // text and neutral boxes
const G = "#b5afc9"; // secondary text

// Same invisible frame in both layers keeps their viewBoxes identical.
const frame = (id) => ({ type: "rectangle", id, x: -40, y: -30, width: 1800, height: 880,
  strokeColor: "transparent", backgroundColor: "transparent", roughness: 0 });

const text = (id, cx, y, t, fontSize, color) =>
  ({ type: "text", id, x: 0, y, cx, text: t, fontSize, strokeColor: color });

const box = (id, x, y, width, height, label, color, labelColor = color, fontSize = 36) => ({
  type: "rectangle", id, x, y, width, height, strokeColor: color, backgroundColor: "transparent",
  strokeWidth: 3, roundness: { type: 3 }, label: { text: label, fontSize, strokeColor: labelColor },
});

const arrow = (id, cx, color) => ({
  type: "arrow", id, x: cx, y: 345, width: 0, height: 110, points: [[0, 0], [0, 110]],
  strokeColor: color, strokeWidth: 3, endArrowhead: "arrow",
});

const column = (p, cx, color, title, quote, who, outputs, details) => [
  text(`${p}-title`, cx, 0, title, 64, color),
  text(`${p}-quote`, cx, 88, quote, 40, color),
  text(`${p}-who`, cx, 160, who, 30, G),
  box(`${p}-input`, cx - 150, 225, 300, 105, "input", W),
  arrow(`${p}-arrow`, cx, color),
  ...outputs,
  text(`${p}-outputs`, cx, 630, `outputs ${p === "s1" ? "decisions" : "text"}`, 50, color),
  text(`${p}-d1`, cx, 735, details[0], 32, W),
  text(`${p}-d2`, cx, 790, details[1], 32, W),
];

export const system1 = [
  frame("f1"),
  ...column("s1", 330, O, "System 1", '"thinking fast"', "Jev", [
    box("s1-noul", 95, 470, 140, 115, "noul", O, O, 32),
    box("s1-choice", 260, 470, 140, 115, "choice", O, O, 32),
    box("s1-score", 425, 470, 140, 115, "score", O, O, 32),
  ], ["one parallel pass, 70–500 ms", "picks only from your options"]),
  { type: "line", id: "divider", x: 835, y: -10, width: 0, height: 840, points: [[0, 0], [0, 840]],
    strokeColor: "#8b84a3", strokeWidth: 2, strokeStyle: "dashed" },
];

export const system2 = [
  frame("f2"),
  ...column("s2", 1340, B, "System 2", '"thinking slow"', "Claude, GPT and other LLMs", [
    box("s2-text", 1120, 470, 440, 115, "free-form text", B, B, 36),
  ], ["writes token by token, seconds to minutes", "can say anything"]),
];
