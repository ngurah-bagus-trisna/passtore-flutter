class PasswordEntry {
  const PasswordEntry({
    this.id,
    required this.title,
    this.username,
    required this.secret,
    required this.salt,
    this.url,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String? username;
  final String secret;
  final String salt;
  final String? url;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordEntry copyWith({
    int? id,
    String? title,
    String? username,
    String? secret,
    String? salt,
    String? url,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      secret: secret ?? this.secret,
      salt: salt ?? this.salt,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'secret': secret,
      'salt': salt,
      'url': url,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory PasswordEntry.fromMap(Map<String, Object?> map) {
    return PasswordEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      username: map['username'] as String?,
      secret: map['secret'] as String,
      salt: map['salt'] as String,
      url: map['url'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}


