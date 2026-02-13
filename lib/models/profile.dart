class Profile {
  final String id;
  final String email;
  final String displayName;
  final String preferredLocale;
  final String preferredTheme;
  final String currency;
  final String avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.email,
    required this.displayName,
    this.preferredLocale = 'fr',
    this.preferredTheme = 'light',
    this.currency = 'CFA',
    this.avatar = 'avatar_1',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      preferredLocale: json['preferred_locale'] as String? ?? 'fr',
      preferredTheme: json['preferred_theme'] as String? ?? 'light',
      currency: json['currency'] as String? ?? 'CFA',
      avatar: json['avatar'] as String? ?? 'avatar_1',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'preferred_locale': preferredLocale,
      'preferred_theme': preferredTheme,
      'currency': currency,
      'avatar': avatar,
    };
  }

  Profile copyWith({
    String? displayName,
    String? preferredLocale,
    String? preferredTheme,
    String? currency,
    String? avatar,
  }) {
    return Profile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      preferredTheme: preferredTheme ?? this.preferredTheme,
      currency: currency ?? this.currency,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
