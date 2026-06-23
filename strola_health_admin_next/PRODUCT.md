# Product

## Register

product

## Users

Strolla Health internal staff holding `admin` or `super_admin` roles in the
FastAPI backend's RBAC: content moderators, customer support, and platform
operators. They open this multiple times a day for short, focused sessions —
reviewing a report, banning a user, curating this month's challenge, checking
yesterday's numbers. They are not the consumer brand's audience and should
never feel marketed to.

## Product Purpose

The staff-facing control surface for the Strolla Health fitness/wellness app:
user search and account actions (ban/unban, grant premium), content
moderation (hide/delete posts, remove photos, resolve user reports),
challenge and badge curation, and engagement analytics (DAU, event funnel,
subscription mix). Built against an already-implemented FastAPI + Firestore
backend; this pass uses realistic dummy data standing in for live API calls.
Success looks like: a moderator resolves a report in under 10 seconds without
leaving the keyboard.

## Brand Personality

Calm, precise, fast. Deliberately distinct from the consumer app's warm
coral/blush wellness identity — this is an instrument panel, not a marketing
surface. Three words: restrained, instrumented, fast.

## Anti-references

Generic admin-template look (Bootstrap-admin, default shadcn dashboard demo,
AdminLTE-style sidebars). Cluttered enterprise SaaS with information
overload and inconsistent component vocabulary screen to screen. Anything
that imports the consumer app's coral/blush palette.

## Design Principles

- The tool disappears into the task — earned familiarity (Linear, Stripe
  Dashboard, Vercel) over novelty.
- Visual data first: a number that can be shown as a trend, distribution, or
  comparison is, not just printed as a stat.
- One component vocabulary across every page — the same button is the same
  button everywhere.
- Motion communicates state changes only, never decoration.
- Density without clutter — staff working in this all day need information,
  not whitespace for its own sake.

## Accessibility & Inclusion

WCAG AA minimum (AAA target for body text contrast). Every destructive or
state-changing action (ban, hide, resolve, delete) must be fully reachable
and operable by keyboard, not just mouse. Respects `prefers-reduced-motion`.
