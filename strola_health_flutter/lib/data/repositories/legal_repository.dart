import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/domain/entities/legal_document.dart';

/// `legalDocumentVersions` is directly Firestore-readable for a signed-in
/// user when `status == 'published'` (see firestore.rules), no callable
/// needed for reading. Recording acceptance still goes through
/// `recordLegalAcceptance`, which looks up the currently published version
/// server-side itself.
class LegalRepository {
  /// Null if nothing has been published for this doc type yet — real state,
  /// not an error (see strola_health_super_admin_next's Legal page: content
  /// is deliberately left empty pending the client's own legal review).
  Future<LegalDocument?> getPublished(LegalDocType docType) async {
    final snap = await FirebaseClient.firestore
        .collection('legalDocumentVersions')
        .where('doc_type', isEqualTo: docType.apiValue)
        .where('status', isEqualTo: 'published')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LegalDocument.fromFirestore(snap.docs.first.data());
  }

  Future<void> recordAcceptance(
    LegalDocType docType, {
    required bool accepted,
  }) {
    return FirebaseClient.call('recordLegalAcceptance', {
      'docType': docType.apiValue,
      'accepted': accepted,
    });
  }
}
