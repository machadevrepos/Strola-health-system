const numberFormatter = new Intl.NumberFormat("en-GB");
const compactFormatter = new Intl.NumberFormat("en-GB", { notation: "compact", maximumFractionDigits: 1 });
const dateFormatter = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric" });
const dateTimeFormatter = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });

export function formatNumber(n: number): string {
  return numberFormatter.format(n);
}

export function formatCompact(n: number): string {
  return compactFormatter.format(n);
}

export function formatCurrencyGBP(n: number): string {
  return `£${numberFormatter.format(Math.round(n))}`;
}

/** "+12.4%" / "-3.1%" — signed, one decimal place, for period-over-period
 * growth stats. Null (no prior-period baseline) renders as an em dash. */
/** "42.0%" — unsigned, one decimal place, for level metrics like a
 * conversion or churn rate. Null renders as an em dash. */
export function formatPercent(pct: number | null): string {
  if (pct === null) return "—";
  return `${pct.toFixed(1)}%`;
}

export function formatSignedPercent(pct: number | null): string {
  if (pct === null) return "—";
  const sign = pct > 0 ? "+" : "";
  return `${sign}${pct.toFixed(1)}%`;
}

export function formatDate(iso: string): string {
  return dateFormatter.format(new Date(iso));
}

export function formatDateTime(iso: string): string {
  return dateTimeFormatter.format(new Date(iso));
}

export function formatDistance(meters: number): string {
  return meters >= 1000 ? `${(meters / 1000).toFixed(2)} km` : `${Math.round(meters)} m`;
}

/** "3m 42s" / "1h 05m" — for durations under an hour, seconds are shown; at an hour or more, minutes are zero-padded and seconds are dropped. */
export function formatDuration(seconds: number): string {
  const total = Math.round(seconds);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  if (h > 0) return `${h}h ${String(m).padStart(2, "0")}m`;
  return `${m}m ${s}s`;
}

export function formatRelative(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const diffMin = Math.round(diffMs / 60_000);
  if (diffMin < 1) return "just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHr = Math.round(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  const diffDay = Math.round(diffHr / 24);
  if (diffDay < 7) return `${diffDay}d ago`;
  return formatDate(iso);
}

/**
 * Title-cases an enum-like value ("prefer_not_to_say" -> "Prefer not to
 * say"). Deliberately not a blanket CSS `capitalize` — that transform
 * capitalizes every word, which mangles units and free-form text ("171 cm"
 * becomes "171 Cm"). Use this only for short enum/label values, at the call
 * site, never as a default on arbitrary content.
 */
export function titleCase(value: string): string {
  const words = value.replace(/_/g, " ").split(" ");
  return words.map((w, i) => (i === 0 && w ? w[0].toUpperCase() + w.slice(1) : w)).join(" ");
}

export const ROLE_LABEL = {
  user: "User",
  admin: "Admin",
  super_admin: "Super admin",
} as const;

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  return name.slice(0, 2).toUpperCase();
}
