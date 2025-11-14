class PasswordEntry {
  const PasswordEntry({
    this.id,
    required this.title,
    this.username,
    required this.secret,
    required this.salt,
    this.encryptedSecret,
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
  final String? encryptedSecret;
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
  String? encryptedSecret,
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
  encryptedSecret: encryptedSecret ?? this.encryptedSecret,
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
  'encrypted_secret': encryptedSecret,
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
  encryptedSecret: map['encrypted_secret'] as String?,
  url: map['url'] as String?,
  notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

class PasswordEntryInput {
  PasswordEntryInput({
    this.id,
    required this.title,
    this.username,
    this.password,
    this.url,
    this.notes,
  });

  final int? id;
  final String title;
  final String? username;
  final String? password;
  final String? url;
  final String? notes;

  PasswordEntryInput copyWith({
    int? id,
    String? title,
    String? username,
    String? password,
    String? url,
    String? notes,
  }) {
    return PasswordEntryInput(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
    );
  }
}


