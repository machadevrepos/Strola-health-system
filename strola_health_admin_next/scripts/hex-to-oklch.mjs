// One-off conversion script — not part of the app build. Run with:
//   node scripts/hex-to-oklch.mjs
// Converts the mobile app's exact AppColors hex values to OKLCH so the admin
// panel's CSS custom properties reproduce them precisely (per project rule:
// OKLCH only in the stylesheet, but the *values* must match the brand exactly).

function srgbToLinear(c) {
  c /= 255;
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function hexToOklch(hex, alpha = 1) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  const lr = srgbToLinear(r), lg = srgbToLinear(g), lb = srgbToLinear(b);

  const l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb;
  const m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb;
  const s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb;

  const l_ = Math.cbrt(l), m_ = Math.cbrt(m), s_ = Math.cbrt(s);

  const L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
  const A = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
  const B = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

  const C = Math.sqrt(A * A + B * B);
  let H = (Math.atan2(B, A) * 180) / Math.PI;
  if (H < 0) H += 360;

  const fmt = (n) => Math.round(n * 1000) / 1000;
  const out = `oklch(${fmt(L)} ${fmt(C)} ${fmt(H)}${alpha < 1 ? ` / ${fmt(alpha)}` : ""})`;
  return out;
}

// Blend a hex color over a white background at a given alpha — used for
// textSecondary/textMuted, which the app defines as #333333 at partial
// opacity over a white surface, not as standalone alpha colors.
function blendOverWhite(hex, alpha) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  const blend = (c) => Math.round(c * alpha + 255 * (1 - alpha));
  const toHex = (n) => n.toString(16).padStart(2, "0");
  return `#${toHex(blend(r))}${toHex(blend(g))}${toHex(blend(b))}`;
}

// 2026-09-14 palette (warm cream / mocha-rose) — replaces the coral/blush
// set above. textSecondary is now a standalone brand hex, not a blend of
// textPrimary over white, so blendOverWhite() is unused for this palette;
// left in place as it's still correct for the superseded set above.
const colors = {
  bgSurface_FFFFFF: "#FFFFFF",
  bgCard_FFFCFA: "#FFFCFA",
  cardBorder_F3E9E5: "#F3E9E5",
  accent_C38381: "#C38381",
  supporting_D9B6A0: "#D9B6A0",
  supportingStrong_C3A490: "#C3A490", // hand-derived deep peach, matches the Flutter app's goalGradient 2nd stop
  textPrimary_4B342C: "#4B342C",
  textSecondary_9C7063: "#9C7063",
  success_55A56B: "#55A56B",
  error_E25858: "#E25858",
};

console.log("--- Direct hex -> oklch ---");
for (const [name, hex] of Object.entries(colors)) {
  console.log(name.padEnd(24), hexToOklch(hex));
}
