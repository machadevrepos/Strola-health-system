/// Single source of truth for the challenge-invite deep-link domain —
/// `link.strollahealth.com`, backed by `strola_health_firebase`'s `joinPage`
/// Cloud Function (hosting rewrite `/join/**`) and, once registered, iOS
/// Associated Domains / Android App Links so opening the link on a device
/// with the app installed lands straight on that challenge.
class InviteLink {
  InviteLink._();

  static const domain = 'link.strollahealth.com';

  static String forCode(String inviteCode) => 'https://$domain/join/$inviteCode';
}
