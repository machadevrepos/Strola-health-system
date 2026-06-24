import 'dart:convert';

/// Biological sex used for stride and BMR estimation. `other` / `preferNotToSay`
/// fall back to gender-neutral averages in the calculator.
enum Gender { male, female, other, preferNotToSay }

enum UnitSystem { metric, imperial }

/// Why the user picked Strolla — drives onboarding personalization. Multi-select.
enum StrollaReason { strollerWagon, walkingPad, cantWearWearable, accurateTracking, other }

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
        Gender.preferNotToSay => 'Prefer not to say',
      };
}

extension StrollaReasonLabel on StrollaReason {
  String get title => switch (this) {
        StrollaReason.strollerWagon => 'Stroller / wagon walks',
        StrollaReason.walkingPad => 'Walking pad',
        StrollaReason.cantWearWearable => "Can't wear a smart watch/ring at work",
        StrollaReason.accurateTracking => 'Looking for more accurate step tracking',
        StrollaReason.other => 'Other',
      };

  String? get subtitle => switch (this) {
        StrollaReason.cantWearWearable =>
          'e.g. healthcare worker, food service worker, etc.',
        _ => null,
      };
}

/// The user's identity + body metrics needed for accurate fitness math.
///
/// Note: daily step goal and body weight are intentionally NOT stored here —
/// they live in their own persisted providers (`dailyGoalProvider`,
/// `userWeightKgProvider`) which the rest of the app already watches.
class UserProfile {
  const UserProfile({
    this.username = '',
    this.name = '',
    this.location,
    this.bio,
    this.photoPath,
    this.heightCm = 170,
    this.gender = Gender.preferNotToSay,
    this.dateOfBirth,
    this.reasons = const {},
    this.units = UnitSystem.metric,
    this.onboardingComplete = false,
  });

  final String username;
  final String name;
  final String? location;
  final String? bio;
  final String? photoPath;
  final double heightCm;
  final Gender gender;
  final DateTime? dateOfBirth;
  final Set<StrollaReason> reasons;
  final UnitSystem units;
  final bool onboardingComplete;

  UserProfile copyWith({
    String? username,
    String? name,
    String? location,
    String? bio,
    String? photoPath,
    double? heightCm,
    Gender? gender,
    DateTime? dateOfBirth,
    Set<StrollaReason>? reasons,
    UnitSystem? units,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      username: username ?? this.username,
      name: name ?? this.name,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      photoPath: photoPath ?? this.photoPath,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      reasons: reasons ?? this.reasons,
      units: units ?? this.units,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'name': name,
        'location': location,
        'bio': bio,
        'photoPath': photoPath,
        'heightCm': heightCm,
        'gender': gender.name,
        'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
        'reasons': reasons.map((r) => r.name).toList(),
        'units': units.name,
        'onboardingComplete': onboardingComplete,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      photoPath: json['photoPath'] as String?,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 170,
      gender: Gender.values.byName(json['gender'] as String? ?? 'preferNotToSay'),
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['dateOfBirth'] as int),
      reasons: ((json['reasons'] as List?) ?? [])
          .map((r) => StrollaReason.values.byName(r as String))
          .toSet(),
      units: UnitSystem.values.byName(json['units'] as String? ?? 'metric'),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }

  String encode() => jsonEncode(toJson());

  factory UserProfile.decode(String source) =>
      UserProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
