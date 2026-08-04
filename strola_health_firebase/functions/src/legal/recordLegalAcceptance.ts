import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument, notFound } from "../lib/auth-helpers";
import type { LegalDocType, LegalDocumentVersion } from "../lib/types";

/** Function #48. The app-side gate publishLegalVersion's fan-out is staged
 * for — records a user's accept/decline of the currently published version. */
export const recordLegalAcceptance = onCall(async (request) => {
  const uid = requireAuth(request);
  const { docType, accepted } = (request.data ?? {}) as { docType?: LegalDocType; accepted?: boolean };
  if (!docType || accepted === undefined) invalidArgument("docType and accepted are required.");

  const publishedSnap = await db
    .collection(Collections.legalDocumentVersions)
    .where("doc_type", "==", docType)
    .where("status", "==", "published")
    .limit(1)
    .get();
  if (publishedSnap.empty) notFound("No published version for this document.");
  const version = (publishedSnap.docs[0].data() as LegalDocumentVersion).version;

  const id = `${uid}_${docType}`;
  await db
    .collection(Collections.legalAcceptances)
    .doc(id)
    .set({
      id,
      user_id: uid,
      doc_type: docType,
      version,
      status: accepted ? "accepted" : "declined",
      responded_at: FieldValue.serverTimestamp(),
    });

  return { success: true };
});
