import { onRequest } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { Challenge } from "../lib/types";

/**
 * Function #22c. Publicly hosted invite-link landing page — Firebase
 * Hosting rewrites `/join/**` here on link.strollahealth.com (see
 * firebase.json), so a "Share Invite Link" tap on a private challenge opens
 * this instead of a bare invite code. Reads via the Admin SDK (challenges
 * are already readable by any signed-in client per firestore.rules, but
 * this page has no signed-in user), so it can render a preview even before
 * the visitor is signed into the app. Doesn't perform the join itself —
 * that only happens client-side once the app opens and the deep-link
 * listener (lib/core/services/deep_link_listener.dart) calls the
 * `joinChallenge` callable as an authenticated user; a bare GET on this
 * page must stay side-effect-free.
 */

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function page({ title, bodyHtml, redirectUrl }: { title: string; bodyHtml: string; redirectUrl?: string }): string {
  // Attempts the app-side custom scheme immediately on load — if the app is
  // installed and the OS hands it off, the visitor never sees this page
  // render further. If they're still here after a beat, nothing intercepted
  // it (app not installed, or opened from a context that doesn't support
  // scheme handoff) and the static fallback content below stays visible.
  const redirectScript = redirectUrl
    ? `<script>window.location.href = ${JSON.stringify(redirectUrl)};</script>`
    : "";

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} — Strolla Health</title>
<meta name="robots" content="noindex">
<style>
  :root { color-scheme: light; }
  body { margin: 0; padding: 0; background: #FFF2F2; color: #333333; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 480px; margin: 0 auto; padding: 56px 24px; text-align: center; }
  .brand { font-weight: 800; font-size: 20px; letter-spacing: -0.4px; color: #E07A7A; margin-bottom: 40px; }
  .badge { font-size: 56px; line-height: 1; margin-bottom: 16px; }
  h1 { font-size: 24px; font-weight: 700; letter-spacing: -0.4px; margin: 0 0 8px; }
  p { line-height: 1.6; margin: 0 0 24px; color: rgba(51,51,51,0.7); }
  .code { display: inline-block; background: #FFFFFF; border: 1px solid rgba(224,122,122,0.25); border-radius: 14px; padding: 16px 28px; font-size: 22px; font-weight: 800; letter-spacing: 3px; color: #E07A7A; margin-bottom: 28px; }
  .cta { display: inline-block; background: #E07A7A; color: #FFFFFF; font-weight: 700; text-decoration: none; padding: 14px 28px; border-radius: 14px; margin-bottom: 12px; }
  .hint { font-size: 13px; color: rgba(51,51,51,0.5); }
  .empty { padding: 40px 0; }
</style>
${redirectScript}
</head>
<body>
<main>
  <div class="brand">strolla</div>
  ${bodyHtml}
</main>
</body>
</html>`;
}

export const joinPage = onRequest(async (req, res) => {
  const inviteCode = req.path.replace(/^\/join\/?/, "").replace(/\/$/, "");

  if (!inviteCode) {
    res
      .status(404)
      .set("Content-Type", "text/html; charset=utf-8")
      .set("Cache-Control", "no-store")
      .send(page({ title: "Not found", bodyHtml: `<div class="empty"><h1>Not found</h1><p>No invite code in this link.</p></div>` }));
    return;
  }

  const snap = await db.collection(Collections.challenges).where("invite_code", "==", inviteCode).limit(1).get();

  if (snap.empty) {
    res
      .status(404)
      .set("Content-Type", "text/html; charset=utf-8")
      .set("Cache-Control", "no-store")
      .send(
        page({
          title: "Invite not found",
          bodyHtml: `<div class="empty"><h1>Invite not found</h1><p>This invite link is invalid or has expired.</p></div>`,
        })
      );
    return;
  }

  const challenge = snap.docs[0].data() as Challenge;

  if (challenge.status === "archived") {
    res
      .status(200)
      .set("Content-Type", "text/html; charset=utf-8")
      .set("Cache-Control", "no-store")
      .send(
        page({
          title: challenge.title,
          bodyHtml: `<div class="empty"><h1>${escapeHtml(challenge.title)}</h1><p>This challenge has already ended.</p></div>`,
        })
      );
    return;
  }

  // Handed to the OS immediately (see the redirect script in `page()`); the
  // Flutter side's `_inviteCodeFrom` in deep_link_listener.dart parses
  // `join` back out of the scheme's host component for this exact shape.
  const appLink = `strolahealthlink://join/${encodeURIComponent(inviteCode)}`;

  const bodyHtml = `
    <div class="badge">${escapeHtml(challenge.badge_emoji || "🏆")}</div>
    <h1>${escapeHtml(challenge.title)}</h1>
    <p>You've been invited to join this challenge on Strolla Health.</p>
    <div class="code">${escapeHtml(inviteCode)}</div>
    <p><a class="cta" href="${appLink}">Open in Strolla Health</a></p>
    <p class="hint">Don't have the app yet? Install Strolla Health, sign in, then open this link again or enter the code above from Create Challenge.</p>
  `;

  res
    .status(200)
    .set("Content-Type", "text/html; charset=utf-8")
    .set("Cache-Control", "public, max-age=60")
    .send(page({ title: challenge.title, bodyHtml, redirectUrl: appLink }));
});
