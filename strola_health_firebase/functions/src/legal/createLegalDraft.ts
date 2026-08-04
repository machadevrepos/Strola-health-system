import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, invalidArgument } from "../lib/auth-helpers";
import type { LegalDocType, LegalDocumentVersion } from "../lib/types";

async function nextVersionNumber(docType: LegalDocType): Promise<number> {
  const snap = await db
    .collection(Collections.legalDocumentVersions)
    .where("doc_type", "==", docType)
    .orderBy("version", "desc")
    .limit(1)
    .get();
  return snap.empty ? 1 : (snap.docs[0].data() as LegalDocumentVersion).version + 1;
}

/** Function #46a. Seeded from the currently-published content when the
 * caller doesn't supply its own starting content. */
export const createLegalDraft = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { docType, content } = (request.data ?? {}) as { docType?: LegalDocType; content?: string };
  if (!docType) invalidArgument("docType is required.");

  let seedContent = content;
  if (seedContent === undefined) {
    const publishedSnap = await db
      .collection(Collections.legalDocumentVersions)
      .where("doc_type", "==", docType)
      .where("status", "==", "published")
      .limit(1)
      .get();
    seedContent = publishedSnap.empty ? "" : (publishedSnap.docs[0].data() as LegalDocumentVersion).content;
  }

  const version = await nextVersionNumber(docType!);
  const ref = db.collection(Collections.legalDocumentVersions).doc();
  await ref.set({
    id: ref.id,
    doc_type: docType,
    version,
    status: "draft",
    content: seedContent,
    changelog: null,
    effective_date: null,
    requires_reaccept: false,
    created_by: callerUid,
    created_at: FieldValue.serverTimestamp(),
    published_at: null,
  });

  return { success: true, versionId: ref.id, version };
});
