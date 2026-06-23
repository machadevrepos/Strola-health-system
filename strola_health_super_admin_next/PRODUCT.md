# Product

## Register

product

## Users

Strolla Health staff holding the `super_admin` role in the FastAPI backend's
RBAC — founders and platform operators, a much smaller group than regular
`admin` staff. They get everything the Admin console offers (user search,
moderation, challenges/badges, analytics) plus the handful of actions the
backend gates to `super_admin` alone: hardware fleet provisioning, feature
flag configuration, and promoting/demoting other staff's roles. They are not
the consumer brand's audience and should never feel marketed to.

## Product Purpose

The platform-control surface for Strolla Health: everything in the regular
Admin console, plus the elevated, harder-to-reverse actions reserved for
super admins — provisioning and force-unpairing hardware from the fleet,
toggling feature-gate config, and granting or revoking admin/super_admin
access for other staff. Built against an already-implemented FastAPI +
Firestore backend; this pass uses realistic dummy data standing in for live
API calls. Success looks like: a founder can provision a batch of devices or
promote a new support hire without touching a database console.

## Brand Personality

Calm, precise, fast — and a notch more serious than the Admin console, since
every exclusive action here (re-provisioning hardware, changing who else has
admin access) has a wider blast radius. Same coral/blush identity as the
rest of the Strolla Health product family (mobile app and Admin console) —
this is one brand operated from different rooms, not a different product.
Three words: restrained, instrumented, deliberate.

## Anti-references

Generic admin-template look (Bootstrap-admin, default shadcn dashboard demo,
AdminLTE-style sidebars). Cluttered enterprise SaaS with information
overload and inconsistent component vocabulary screen to screen. A "command
center" aesthetic that makes routine config changes feel like launching a
rocket — the elevated actions here need clear confirmation, not melodrama.

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
