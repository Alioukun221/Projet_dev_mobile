class Category {
  final String? id;
  final String? userId;
  String name;
  String icon;
  final bool isDefault;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    this.id,
    this.userId,
    required this.name,
    this.icon = '0xe148',
    this.isDefault = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '0xe148',
      isDefault: json['is_default'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'is_default': isDefault,
      'is_deleted': isDeleted,
    };
  }

  Category copyWith({
    String? name,
    String? icon,
    bool? isDefault,
    bool? isDeleted,
  }) {
    return Category(
      id: id,
      userId: userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
