// Selection-based transforms shared by every toolbar-driven plain-textarea
// editor in the admin (legal documents, app content) — each returns the new
// full text plus where the selection should land afterward, so the caller
// can restore focus/selection without knowing the transform's internals.
export interface TransformResult {
  text: string;
  start: number;
  end: number;
}

export function wrapSelection(text: string, start: number, end: number, prefix: string, suffix: string): TransformResult {
  const selected = text.slice(start, end) || "text";
  const next = text.slice(0, start) + prefix + selected + suffix + text.slice(end);
  return { text: next, start: start + prefix.length, end: start + prefix.length + selected.length };
}

export function insertLink(text: string, start: number, end: number): TransformResult {
  const label = text.slice(start, end) || "link text";
  const token = `[${label}](https://)`;
  const next = text.slice(0, start) + token + text.slice(end);
  const urlStart = start + label.length + 3; // just after "[label]("
  return { text: next, start: urlStart, end: urlStart + "https://".length };
}
