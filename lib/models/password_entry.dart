class PasswordEntry {
  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get hashPreview => passwordHash.length <= 8
      ? passwordHash
      : '${passwordHash.substring(0, 6)}••';

  PasswordEntry copyWith({
    int? id,
    String? title,
    String? username,
    String? passwordHash,
    String? passwordSalt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as int,
      title: map['title'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      passwordSalt: map['password_salt'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class PasswordEntryInput {
  PasswordEntryInput({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    this.notes,
  });

  final int? id;
  final String title;
  final String username;
  final String? password;
  final String? notes;

  PasswordEntryInput copyWith({
    int? id,
    String? title,
    String? username,
    String? password,
    String? notes,
  }) {
    return PasswordEntryInput(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
    );
  }
}

