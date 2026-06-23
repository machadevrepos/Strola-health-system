// One-off interactive audit script — not part of the app build. Drives every
// page with a real headless browser and exercises every dialog, dropdown,
// sheet, tab, and table interaction, capturing console errors and uncaught
// exceptions exactly like the CommandDialog crash that prompted this script.
// Run with: node scripts/hardknock-audit.mjs (dev server must be on :3100)

import { chromium } from "playwright";

const BASE = "http://localhost:3100";
const issues = [];
const seenTexts = new Set();

function record(page, kind, text) {
  const key = `${page}::${kind}::${text}`;
  if (seenTexts.has(key)) return;
  seenTexts.add(key);
  issues.push({ page, kind, text });
}

async function withPage(browser, label, fn) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.on("console", (msg) => {
    if (msg.type() === "error") record(label, "console.error", msg.text());
  });
  page.on("pageerror", (err) => record(label, "pageerror", err.stack || err.message));
  page.on("requestfailed", (req) => {
    const failure = req.failure();
    if (failure && !req.url().includes("favicon")) {
      record(label, "requestfailed", `${req.url()} — ${failure.errorText}`);
    }
  });
  try {
    await fn(page);
  } catch (err) {
    record(label, "script-error", err.message);
  } finally {
    await page.close();
  }
}

async function safeClick(page, label, selector, opts = {}) {
  try {
    // page.waitForSelector proved far more reliable than Locator.waitFor for
    // freshly-portaled dialog content in this script — use it to absorb
    // render/animation races before resolving the click target.
    try {
      await page.waitForSelector(selector, { timeout: 3000 });
    } catch {
      record(label, "missing-element", `selector not found: ${selector}`);
      return false;
    }
    const loc = page.locator(selector).first();
    await loc.click({ timeout: 3000, ...opts });
    await page.waitForTimeout(200);
    return true;
  } catch (err) {
    record(label, "interaction-error", `${selector}: ${err.message}`);
    return false;
  }
}

async function pressEscape(page) {
  await page.keyboard.press("Escape");
  await page.waitForTimeout(150);
}

const run = async () => {
  const browser = await chromium.launch();

  // ---- Overview ----
  await withPage(browser, "/", async (page) => {
    await page.goto(BASE + "/", { waitUntil: "networkidle" });
    await page.waitForTimeout(500);
  });

  // ---- Command palette (the bug we just found) ----
  await withPage(browser, "/ (cmd+k)", async (page) => {
    await page.goto(BASE + "/", { waitUntil: "networkidle" });
    await page.keyboard.press("Control+k");
    await page.waitForTimeout(300);
    await page.keyboard.type("users");
    await page.waitForTimeout(300);
    await pressEscape(page);
    // also test the visible search button trigger
    await safeClick(page, "/ (cmd+k)", "text=Search or jump to");
    await pressEscape(page);
  });

  // ---- Users list ----
  await withPage(browser, "/users", async (page) => {
    await page.goto(BASE + "/users", { waitUntil: "networkidle" });
    await page.waitForTimeout(300);

    // filters
    await safeClick(page, "/users", "button:has-text('All roles')");
    await pressEscape(page);
    await safeClick(page, "/users", "button:has-text('All statuses')");
    await pressEscape(page);

    // search
    await page.locator("input[placeholder*='Search']").first().fill("a").catch(() => {});
    await page.waitForTimeout(200);
    await page.locator("input[placeholder*='Search']").first().fill("").catch(() => {});

    // row actions dropdown (first row's "...")
    const dotsButtons = page.locator("button[aria-label^='Actions for']");
    const dotsCount = await dotsButtons.count();
    if (dotsCount > 0) {
      await dotsButtons.first().click();
      await page.waitForTimeout(200);
      await pressEscape(page);
    } else {
      record("/users", "missing-element", "no row action buttons found");
    }

    // bulk select: check first row checkbox (Base UI checkbox root, not the sr-only native input)
    const checkboxes = page.locator("table [data-slot='checkbox']");
    if (await checkboxes.count() > 1) {
      await checkboxes.nth(1).click().catch((e) => record("/users", "interaction-error", `checkbox: ${e.message}`));
      await page.waitForTimeout(200);
      // bulk bar should now show "Clear"
      await safeClick(page, "/users", "button:has-text('Clear')");
    } else {
      record("/users", "missing-element", "fewer than 2 row checkboxes found");
    }

    // pagination
    await safeClick(page, "/users", "button[aria-label='Next page']");
    await page.waitForTimeout(150);
    await safeClick(page, "/users", "button[aria-label='Previous page']");

    // export
    await safeClick(page, "/users", "button:has-text('Export CSV')");
  });

  // ---- User detail (cover trial, kickstarter-comp, banned, deleted) ----
  for (const id of ["usr_001", "usr_007", "usr_011", "usr_013", "usr_021"]) {
    await withPage(browser, `/users/${id}`, async (page) => {
      await page.goto(`${BASE}/users/${id}`, { waitUntil: "networkidle" });
      await page.waitForTimeout(300);

      // tabs
      for (const tab of ["Activity", "Devices", "Badges", "Challenges", "Profile"]) {
        await safeClick(page, `/users/${id}`, `[role='tab']:has-text('${tab}')`);
        await page.waitForTimeout(150);
      }

      // header actions are deliberately absent for deleted accounts — don't
      // treat their absence as a defect, just confirm the rest of the page.
      const isDeleted = (await page.locator("text=Deleted").count()) > 0;
      if (isDeleted) return;

      await safeClick(page, `/users/${id}`, "button:has-text('Edit profile')");
      await pressEscape(page);

      // grant/revoke premium
      const revoke = page.locator("button:has-text('Revoke premium')");
      if (await revoke.count() > 0) {
        await revoke.first().click();
        await page.waitForTimeout(200);
        await pressEscape(page);
      } else {
        const grantMenu = page.locator("button:has-text('Grant premium')");
        if (await grantMenu.count() > 0) {
          await grantMenu.first().click();
          await page.waitForTimeout(200);
          await safeClick(page, `/users/${id}`, "[role='menuitem']:has-text('30 days')");
          // confirm dialog should now be open — scope to the dialog since its
          // confirm button shares text with the original trigger underneath
          await safeClick(page, `/users/${id}`, "[role='alertdialog'] button:has-text('Grant premium')", {});
          await page.waitForTimeout(150);
          await pressEscape(page);
        }
      }

      // role select -> confirm dialog -> cancel
      const roleTrigger = page.locator("[aria-label='Change role']");
      if (await roleTrigger.count() > 0) {
        await roleTrigger.first().click();
        await page.waitForTimeout(200);
        await safeClick(page, `/users/${id}`, "[role='option']:has-text('Admin')");
        await page.waitForTimeout(200);
        // a confirm dialog should appear; cancel it
        await safeClick(page, `/users/${id}`, "button:has-text('Cancel')");
      }

      // ban / unban — check for "Unban" first: ":has-text('Ban')" alone would
      // also match "Unban" as a substring, which silently no-ops (unban has
      // no confirm step) and produces a misleading "Cancel not found" below.
      const unbanBtn = page.locator("button:has-text('Unban')");
      if (await unbanBtn.count() > 0) {
        await safeClick(page, `/users/${id}`, "button:has-text('Unban')");
      } else {
        await safeClick(page, `/users/${id}`, "button:has-text('Ban')");
        await page.waitForTimeout(200);
        await safeClick(page, `/users/${id}`, "button:has-text('Cancel')");
      }

      // delete (open + cancel, never confirm)
      const deleteBtn = page.locator("button:has-text('Delete')").first();
      if (await deleteBtn.count() > 0) {
        await deleteBtn.click();
        await page.waitForTimeout(200);
        await safeClick(page, `/users/${id}`, "button:has-text('Cancel')");
      }

      // badges tab: award select
      await safeClick(page, `/users/${id}`, "[role='tab']:has-text('Badges')");
      await page.waitForTimeout(150);
      await safeClick(page, `/users/${id}`, "text=Award a badge");
      await pressEscape(page);

      // privacy switches
      await safeClick(page, `/users/${id}`, "[role='tab']:has-text('Profile')");
      await page.waitForTimeout(150);
      const switches = page.locator("[role='switch']");
      if (await switches.count() > 0) {
        await switches.first().click().catch((e) => record(`/users/${id}`, "interaction-error", `switch: ${e.message}`));
      }
    });
  }

  // ---- Moderation ----
  await withPage(browser, "/moderation", async (page) => {
    await page.goto(BASE + "/moderation", { waitUntil: "networkidle" });
    await page.waitForTimeout(300);

    await safeClick(page, "/moderation", "[role='tab']:has-text('All posts')");
    await page.waitForTimeout(200);

    // post actions dropdown
    await safeClick(page, "/moderation", "button[aria-label='Post actions']");
    await page.waitForTimeout(150);
    await pressEscape(page);

    // load more
    await safeClick(page, "/moderation", "button:has-text('Load')");

    // back to reports, resolve dialog
    await safeClick(page, "/moderation", "[role='tab']:has-text('Reports')");
    await page.waitForTimeout(200);
    const resolveBtn = page.locator("button:has-text('Resolve')").first();
    if (await resolveBtn.count() > 0) {
      await resolveBtn.click();
      await page.waitForTimeout(200);
      await pressEscape(page);
    }
  });

  // ---- Challenges & Badges ----
  await withPage(browser, "/challenges", async (page) => {
    await page.goto(BASE + "/challenges", { waitUntil: "networkidle" });
    await page.waitForTimeout(300);

    await safeClick(page, "/challenges", "button:has-text('Create challenge')");
    await page.waitForTimeout(200);
    await pressEscape(page);

    await safeClick(page, "/challenges", "button[aria-label='Challenge actions']");
    await page.waitForTimeout(150);
    await pressEscape(page);

    await safeClick(page, "/challenges", "[role='tab']:has-text('Badges')");
    await page.waitForTimeout(200);
    await safeClick(page, "/challenges", "button:has-text('Create badge')");
    await page.waitForTimeout(200);
    await pressEscape(page);
    await safeClick(page, "/challenges", "button[aria-label='Badge actions']");
    await page.waitForTimeout(150);
    await pressEscape(page);

    // back to the Challenges tab, then click a card to navigate to detail
    await safeClick(page, "/challenges", "[role='tab']:has-text('Challenges')");
    await page.waitForTimeout(200);
    await safeClick(page, "/challenges", ".cursor-pointer:has-text('10K Daily Streak')");
    await page.waitForTimeout(400);
  });

  await withPage(browser, "/challenges/chal_001", async (page) => {
    await page.goto(BASE + "/challenges/chal_001", { waitUntil: "networkidle" });
    await page.waitForTimeout(300);
    await safeClick(page, "/challenges/chal_001", "button[aria-label='Remove participant']");
    await page.waitForTimeout(200);
    await safeClick(page, "/challenges/chal_001", "button:has-text('Cancel')");
  });

  // ---- Settings ----
  await withPage(browser, "/settings", async (page) => {
    await page.goto(BASE + "/settings", { waitUntil: "networkidle" });
    await page.waitForTimeout(300);

    await safeClick(page, "/settings", "button:has-text('Provision device')");
    await page.waitForTimeout(200);
    await pressEscape(page);

    await safeClick(page, "/settings", "[role='tab']:has-text('Feature flags')");
    await page.waitForTimeout(200);

    await safeClick(page, "/settings", "[role='tab']:has-text('Activity log')");
    await page.waitForTimeout(200);

    await safeClick(page, "/settings", "[role='tab']:has-text('Device fleet')");
    await page.waitForTimeout(200);
  });

  await browser.close();

  console.log("\n=== HARDKNOCK AUDIT RESULTS ===\n");
  if (issues.length === 0) {
    console.log("No console errors, page errors, or interaction failures found.");
  } else {
    for (const issue of issues) {
      console.log(`[${issue.page}] (${issue.kind})\n  ${issue.text}\n`);
    }
    console.log(`TOTAL ISSUES: ${issues.length}`);
  }
  process.exit(issues.length > 0 ? 1 : 0);
};

run();
