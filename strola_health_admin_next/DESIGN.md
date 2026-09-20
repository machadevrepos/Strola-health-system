# Design

Documents the as-built admin panel. The palette below superseded an earlier
neutral "ops-tool" direction — the client decided, after seeing the built
screens, that the admin panel should carry the same brand as the consumer
app rather than a deliberately distinct identity. Everything else (layout,
density, motion, Linear-feel) is unchanged from the original direction.

## Visual Theme

Light only. One brand across every Strolla surface: the mobile app's exact
`AppColors` palette, reproduced precisely rather than approximated. As of
2026-09-14 that palette is warm cream / mocha-rose (was coral/blush before).
Layout stays restrained/product-register (Linear-feel chrome, calm density,
charts and tables doing the work) — only the color values changed, not the
compositional rules.

## Color Palette (OKLCH)

Converted from the Flutter app's exact hex values via
`scripts/hex-to-oklch.mjs` (sRGB -> OKLab, not eyeballed) — `oklch()` in the
stylesheet is a format choice, the values themselves match the brand exactly.

```css
:root {
  /* Core — bgSurface / bgCard / textPrimary */
  --background: oklch(1 0 0);                     /* #FFFFFF */
  --card: oklch(0.993 0.004 56.377);               /* #FFFCFA — distinct from background */
  --foreground: oklch(0.349 0.036 39.996);         /* #4B342C */
  --muted-foreground: oklch(0.586 0.06 37.123);    /* #9C7063 — a standalone brand hex now, not a blend */

  /* Brand — accent / cardBorder(accentSecondary) */
  --primary: oklch(0.674 0.08 21.359);             /* #C38381 mocha rose */
  --secondary: oklch(0.941 0.012 43.276);          /* #F3E9E5 — also bgDeep and the border color below */
  --border: oklch(0.941 0.012 43.276);             /* #F3E9E5, full strength — the brief names this as a solid card-border/incomplete-ring color, not an alpha tint */

  /* Semantic — supporting(goalAmber) / success / error */
  --brand-accent: oklch(0.801 0.051 53.957);       /* #D9B6A0 soft peach — used selectively, never as a primary color */
  --success: oklch(0.656 0.117 150.94);            /* #55A56B — unchanged, functional not brand */
  --destructive: oklch(0.641 0.173 23.304);        /* #E25858 — unchanged, functional not brand */
}
```

Rules carried over unchanged: text on any filled `primary`/`destructive`/
`success` surface is white; text on filled `brand-accent` (soft peach) is
dark (`--brand-accent-foreground`, = `--foreground`) — it's a light tint, not
a mid-tone, so dark text is more legible than white. No fourth color gets
introduced; every hue on the page traces back to one of the `AppColors`
values — see the Flutter app's `app_colors.dart` for the full mapping,
including which admin-panel tokens double up on the same underlying hex
(`--secondary`/`--border`/`--sidebar` all resolve to the one `#F3E9E5`, same
as `cardBorder`/`accentSecondary`/`bgDeep` on the Flutter side).

## Typography

**2026-09-15: switched from the single-family Geist system (below, struck
through for context) to Arboria — the same two-family system as the Flutter
app's `AppTypography`, at the user's request to unify typography across
every Strolla surface the way color already was.** This overrides the
original product-register rationale ("one family, no display/body pairing
needed") rather than extending it — worth knowing if a future call wants
that restraint back for the admin panel specifically.

**Arboria Book** for headings (`font-heading` — page titles, section
headers, card/dialog/sheet titles; already wired into every shadcn title
primitive, so this took effect panel-wide with no per-component changes)
and **Arboria Medium** for body copy and numeric/tabular data alike
(`font-sans`/`font-mono` both point at it — the brief has no separate mono
face; step counts and other key numbers just use Medium, same as the
Flutter app). Both are licensed files not yet in the repo (same blocker as
`strola_health_flutter/CLAUDE.md` describes) — see the `@font-face` rules
and comment at the top of `globals.css` for exactly what to drop in and
where. Until then, Geist (still loaded via `next/font/google`) renders as
the automatic fallback — not a plain system font, but not final either.
Fixed rem scale, not fluid/clamp — this is a consistent-DPI desktop tool.

| Token | Size | Weight | Family | Use |
|---|---|---|---|---|
| `text-display` | 1.5rem / 24px | 600 | Book (`font-heading`) | Page titles only |
| `text-title` | 1.125rem / 18px | 600 | Book (`font-heading`) | Section headers, card titles |
| `text-body` | 0.9375rem / 15px | 400 | Medium (`font-sans`) | Default UI text |
| `text-label` | 0.8125rem / 13px | 500 | Medium (`font-sans`) | Form labels, table headers, eyebrow-free section labels |
| `text-caption` | 0.75rem / 12px | 400 | Medium (`font-sans`) | Timestamps, helper text, badge text |
| `text-mono` | 0.875rem / 14px | 500 | Medium (`font-mono`) | All numeric/tabular values — no longer a distinct monospace face |

Scale ratio ~1.15-1.2 between steps, per product-register tightness.

~~One family carries everything (per product register guidance — no
display/body pairing needed). Geist Sans for UI text and Geist Mono for
tabular/numeric data (counts, dates, IDs, percentages).~~

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
