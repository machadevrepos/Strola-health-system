import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import type { LegalDocumentVersion } from "../lib/types";

/** Function #46b. */
export const updateLegalDraft = onCall(async (request) => {
  requireAdmin(request);
  const { versionId, content, effectiveDate, requiresReaccept } = (request.data ?? {}) as {
    versionId?: string;
    content?: string;
    effectiveDate?: string;
    requiresReaccept?: boolean;
  };
  if (!versionId) invalidArgument("versionId is required.");

  const ref = db.collection(Collections.legalDocumentVersions).doc(versionId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Draft not found.");
  const version = snap.data() as LegalDocumentVersion;
  if (version.status !== "draft") failedPrecondition("Only drafts can be edited.");

  const patch: Record<string, unknown> = {};
  if (content !== undefined) patch.content = content;
  if (effectiveDate !== undefined) patch.effective_date = effectiveDate;
  if (requiresReaccept !== undefined) patch.requires_reaccept = requiresReaccept;
  await ref.update(patch);

  return { success: true };
});

/** Function #46c. */
export const discardLegalDraft = onCall(async (request) => {
  requireAdmin(request);
  const { versionId } = (request.data ?? {}) as { versionId?: string };
  if (!versionId) invalidArgument("versionId is required.");

  const ref = db.collection(Collections.legalDocumentVersions).doc(versionId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Draft not found.");
  const version = snap.data() as LegalDocumentVersion;
  if (version.status !== "draft") failedPrecondition("Only drafts can be discarded.");

  await ref.delete();
  return { success: true };
});
