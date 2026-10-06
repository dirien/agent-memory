// "Jev answers in three shapes": noul, choice, score. Three layers with the
// same frame (render-scene.mjs writes shapes1.svg .. shapes3.svg), so the slide
// can reveal one shape per click. Noul and choice examples are illustrations;
// the score example is the one in TypeSafe's docs.
const O = "#ffa94d"; // answers
const W = "#f2effb"; // text and scales
const G = "#b5afc9"; // axis labels
const D = "#8b84a3"; // dividers

const frame = (id) => ({ type: "rectangle", id, x: -40, y: -30, width: 1980, height: 590,
  strokeColor: "transparent", backgroundColor: "transparent", roughness: 0 });
const text = (id, x, y, t, fontSize, color, centred = true) =>
  ({ type: "text", id, x: centred ? 0 : x, y, ...(centred ? { cx: x } : {}), text: t, fontSize, strokeColor: color });
const line = (id, x, y, points, color = W, strokeWidth = 3) =>
  ({ type: "line", id, x, y, points, width: 0, height: 0, strokeColor: color, strokeWidth });

const heading = (p, cx, title, kind) => [
  text(`${p}-h`, cx, 0, title, 46, W),
  text(`${p}-k`, cx, 70, kind, 34, O),
];

// Noul: a probability between 0 and 1
const noul = [
  ...heading("n", 330, "true or false", "Noul"),
  text("n-v", 546, 160, "0.95", 36, O),
  line("n-axis", 90, 255, [[0, 0], [480, 0]]),
  line("n-t0", 90, 230, [[0, 0], [0, 50]]),
  line("n-t1", 570, 230, [[0, 0], [0, 50]]),
  { type: "ellipse", id: "n-dot", x: 526, y: 235, width: 40, height: 40,
    strokeColor: O, backgroundColor: O, fillStyle: "solid", strokeWidth: 2 },
  text("n-0", 90, 300, "0", 30, G),
  text("n-1", 570, 300, "1", 30, G),
  text("n-q", 330, 470, "Is this urgent? 0.95", 38, W),
];

// Choice: one option from your list
const options = ["billing", "sales", "support", "other"];
const choice = [
  ...heading("c", 970, "pick one option", "Choice"),
  ...options.flatMap((o, i) => [
    { type: "rectangle", id: `c-box${i}`, x: 830, y: 150 + i * 75, width: 46, height: 46,
      strokeColor: i === 0 ? O : W, backgroundColor: "transparent", strokeWidth: 3 },
    text(`c-l${i}`, 905, 150 + i * 75, o, 36, i === 0 ? O : W, false),
  ]),
  line("c-tick", 838, 152, [[0, 22], [12, 36], [32, 4]], O, 4),
  text("c-q", 970, 470, "Which team? billing", 38, W),
];

// Score: a position on your ordered levels; it can land between two of them.
// TypeSafe's own example (docs.typesafe.ai/primitives/score): 1.43 on three levels.
const levels = ["cosmetic", "workaround", "blocking"];
const step = 220; // x distance between levels
const score = [
  ...heading("s", 1610, "a number on a scale", "Score"),
  text("s-v", 1390 + 1.43 * step, 125, "1.43", 38, O),
  { type: "diamond", id: "s-mark", x: 1390 + 1.43 * step - 18, y: 180, width: 36, height: 40,
    strokeColor: O, backgroundColor: O, fillStyle: "solid", strokeWidth: 2 },
  line("s-axis", 1390, 255, [[0, 0], [2 * step, 0]]),
  ...levels.flatMap((l, i) => [
    line(`s-t${i}`, 1390 + i * step, 235, [[0, 0], [0, 40]], W, 3),
    text(`s-n${i}`, 1390 + i * step, 290, String(i), 30, G),
    text(`s-l${i}`, 1390 + i * step, 330, l, 28, G),
  ]),
  text("s-q", 1610, 470, "How severe is this bug? 1.43", 38, W),
];

const dividers = [
  line("d1", 650, -10, [[0, 0], [0, 560]], D, 2),
  line("d2", 1290, -10, [[0, 0], [0, 560]], D, 2),
];

export const shapes1 = [frame("f1"), ...noul, ...dividers];
export const shapes2 = [frame("f2"), ...choice];
export const shapes3 = [frame("f3"), ...score];
