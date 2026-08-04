#!/usr/bin/env node
"use strict";

/**
 * Scans every `export const X = onCall(...)` in functions/src/**\/*.ts and
 * flags any whose body never calls one of the auth-helper guards
 * (requireAuth / requireAdmin / requireSuperAdmin / requireRole from
 * lib/auth-helpers.ts). Catches an accidentally-unprotected callable before
 * it ships — every real callable in this codebase is meant to gate on at
 * least one of these.
 *
 * Text-based (brace-balancing), not a full TS parse — good enough for this
 * codebase's consistent `export const name = onCall(...)` shape, and it
 * needs no build step to run.
 */

const fs = require("fs");
const path = require("path");

const SRC_DIR = path.resolve(__dirname, "../functions/src");
const AUTH_GUARDS = ["requireAuth(", "requireAdmin(", "requireSuperAdmin(", "requireRole("];
const DECL_RE = /export const (\w+)\s*=\s*onCall\(/g;

/** Explicit, reviewed exceptions — callables that legitimately have no auth
 * guard (e.g. deliberately public) — reasons required inline. Empty for now:
 * every onCall in this backend is expected to gate on a caller identity. */
const ALLOWLIST = new Set([]);

function walk(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walk(full));
    else if (entry.isFile() && entry.name.endsWith(".ts")) out.push(full);
  }
  return out;
}

/** Given the index right after `onCall(`, find the index of the matching
 * close-paren for that call, balancing parens/braces/brackets and skipping
 * over string/template contents so a paren inside a string doesn't confuse it. */
function findCallEnd(text, openIdx) {
  let depth = 1;
  let i = openIdx;
  let quote = null;
  while (i < text.length && depth > 0) {
    const ch = text[i];
    if (quote) {
      if (ch === "\\") i++;
      else if (ch === quote) quote = null;
    } else if (ch === '"' || ch === "'" || ch === "`") {
      quote = ch;
    } else if (ch === "(") {
      depth++;
    } else if (ch === ")") {
      depth--;
    }
    i++;
  }
  return i;
}

function auditFile(file) {
  const text = fs.readFileSync(file, "utf8");
  const findings = [];
  let match;
  DECL_RE.lastIndex = 0;
  while ((match = DECL_RE.exec(text))) {
    const name = match[1];
    if (ALLOWLIST.has(name)) continue;
    const bodyStart = DECL_RE.lastIndex;
    const bodyEnd = findCallEnd(text, bodyStart);
    const body = text.slice(bodyStart, bodyEnd);
    const guarded = AUTH_GUARDS.some((g) => body.includes(g));
    if (!guarded) {
      const line = text.slice(0, match.index).split("\n").length;
      findings.push({ name, line });
    }
  }
  return findings;
}

function main() {
  const files = walk(SRC_DIR);
  let totalCallables = 0;
  const allFindings = [];

  for (const file of files) {
    const rel = path.relative(process.cwd(), file);
    const text = fs.readFileSync(file, "utf8");
    totalCallables += (text.match(/export const \w+\s*=\s*onCall\(/g) || []).length;
    for (const finding of auditFile(file)) {
      allFindings.push({ ...finding, file: rel });
    }
  }

  if (allFindings.length === 0) {
    console.log(`audit:functions-auth — ${totalCallables} onCall callable(s) checked, all gated on an auth helper.`);
    process.exit(0);
  }

  console.error(`audit:functions-auth — ${allFindings.length} of ${totalCallables} callable(s) have no auth guard:\n`);
  for (const f of allFindings) {
    console.error(`  ${f.file}:${f.line}  ${f.name}`);
  }
  console.error(
    "\nEach of these must call requireAuth/requireAdmin/requireSuperAdmin/requireRole, " +
      "or be added to ALLOWLIST in scripts/audit-functions-auth.js with a reason."
  );
  process.exit(1);
}

main();
