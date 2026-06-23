# Design

Documents the as-built admin panel. The palette below superseded an earlier
neutral "ops-tool" direction — the client decided, after seeing the built
screens, that the admin panel should carry the same brand as the consumer
app rather than a deliberately distinct identity. Everything else (layout,
density, motion, Linear-feel) is unchanged from the original direction.

## Visual Theme

Light only. One brand across every Strolla surface: the mobile app's exact
`AppColors` palette (coral accent, blush secondary, blush-tinted background),
reproduced precisely rather than approximated. Layout stays restrained/
product-register (Linear-feel chrome, calm density, charts and tables doing
the work) — only the color values changed, not the compositional rules.

## Color Palette (OKLCH)

Converted from the Flutter app's exact hex values via
`scripts/hex-to-oklch.mjs` (sRGB -> OKLab, not eyeballed) — `oklch()` in the
stylesheet is a format choice, the values themselves match the brand exactly.

```css
:root {
  /* Core — bgSurface / textPrimary */
  --background: oklch(1 0 0);                 /* #FFFFFF */
  --foreground: oklch(0.321 0 0);              /* #333333 */
  --muted-foreground: oklch(0.545 0 0);        /* #333 @ 70% over white (textSecondary) */

  /* Brand — accent / accentSecondary / bgDeep */
  --primary: oklch(0.693 0.127 20.85);         /* #E07A7A coral */
  --secondary: oklch(0.971 0.014 17.398);      /* #FFF2F2 bgDeep */
  --border: oklch(0.825 0.081 18.943 / 0.25);  /* #F6B1B1 @ 25% — exact FlatCard border spec */

  /* Semantic — goalAmber / success / error */
  --brand-accent: oklch(0.8 0.134 81.415);     /* #E9B44C — goal-reached / highlight only */
  --success: oklch(0.656 0.117 150.94);        /* #55A56B — connected-equivalent status only */
  --destructive: oklch(0.641 0.173 23.304);    /* #E25858 */
}
```

Rules carried over unchanged: text on any filled `primary`/`destructive`/
`success` surface is white; text on filled `brand-accent` (goalAmber, L 0.8)
is dark — it reads as light gold, not a mid-tone, so dark text is more
legible than white. No fourth color gets introduced; every hue on the page
traces back to one of the five `AppColors` values.

## Typography

One family carries everything (per product register guidance — no
display/body pairing needed). **Geist Sans** for UI text and **Geist Mono**
for tabular/numeric data (counts, dates, IDs, percentages) — loaded via
`next/font/google` (Geist ships as a Google Font) or `geist` npm package.
Fixed rem scale, not fluid/clamp — this is a consistent-DPI desktop tool.

| Token | Size | Weight | Use |
|---|---|---|---|
| `text-display` | 1.5rem / 24px | 600 | Page titles only |
| `text-title` | 1.125rem / 18px | 600 | Section headers, card titles |
| `text-body` | 0.9375rem / 15px | 400 | Default UI text |
| `text-label` | 0.8125rem / 13px | 500 | Form labels, table headers, eyebrow-free section labels |
| `text-caption` | 0.75rem / 12px | 400 | Timestamps, helper text, badge text |
| `text-mono` | 0.875rem / 14px | 500 | Geist Mono — all numeric/tabular values |

Scale ratio ~1.15-1.2 between steps, per product-register tightness.

## Spacing & Shape

4px base unit. Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48px.
Corner radius lock: **8px** for cards/panels/inputs, **6px** for buttons/
badges/pills at default size, **full** (9999px) only for true pill badges
(status chips). No other radius values anywhere.

Shadows: one elevation only, used sparingly for popovers/dropdowns/modals —
`0 4px 16px oklch(0.20 0.012 220 / 0.10)`. Cards and panels use a 1px
`--color-border` hairline, never a shadow, to separate from `bg`.

## Components

shadcn/ui as the base primitive layer (Radix underneath, owned code, fits
the "Linear-grade restrained product UI" lane cleanly) — fully restyled to
the tokens above, never left in default shadcn visual state. Icons:
Phosphor (`@phosphor-icons/react`), one stroke weight (1.5) throughout.

State coverage required on every interactive component: default, hover,
focus-visible, active, disabled, loading, error, selected. Skeleton loaders
(shape-matched), not spinners, for data fetches.

## Motion

150-250ms on transitions, `cubic-bezier(0.23, 1, 0.32, 1)` (strong ease-out)
for entrances, `scale(0.97)` on button `:active`. Motion communicates state
only: row inserted/removed, panel opened, action confirmed, value changed.
No orchestrated page-load sequences, no decorative idle animation. Popovers
and dropdowns scale in from their trigger origin, not center. Full
`prefers-reduced-motion` fallback (crossfade or instant) throughout.

## Charts

Hand-styled `recharts` primitives (not a pre-themed dashboard kit like
Tremor — every chart is restyled to this palette, never shipped in library
default colors/fonts). Categorical data uses `primary` + neutrals, with
`accent`/`success`/`danger` reserved for genuine semantic meaning (e.g. a
"premium" segment in a subscription breakdown, a "completed" vs "abandoned"
split) rather than decoration.
