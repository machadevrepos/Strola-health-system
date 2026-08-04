enum LegalDocType { privacyPolicy, terms, communityGuidelines }

extension LegalDocTypeX on LegalDocType {
  /// Matches the backend's `LegalDocType` field values exactly (see
  /// strola_health_firebase/functions/src/lib/types.ts) — this is what
  /// goes in the Firestore query and the recordLegalAcceptance call.
  String get apiValue => switch (this) {
    LegalDocType.privacyPolicy => 'privacy_policy',
    LegalDocType.terms => 'terms',
    LegalDocType.communityGuidelines => 'community_guidelines',
  };
}

/// The currently published version of one legal document — mirrors a
/// `legalDocumentVersions` doc where `status == 'published'`.
class LegalDocument {
  const LegalDocument({
    required this.version,
    required this.content,
    required this.effectiveDate,
    required this.requiresReaccept,
  });

  final int version;
  final String content;
  final DateTime? effectiveDate;
  final bool requiresReaccept;

  factory LegalDocument.fromFirestore(Map<String, dynamic> data) {
    return LegalDocument(
      version: (data['version'] as num?)?.toInt() ?? 1,
      content: data['content'] as String? ?? '',
      effectiveDate: data['effective_date'] == null
          ? null
          : DateTime.tryParse(data['effective_date'] as String),
      requiresReaccept: data['requires_reaccept'] as bool? ?? false,
    );
  }
}
