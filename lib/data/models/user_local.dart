class LocalUser {
  final int? id;
  final String email;
  final String password;

  LocalUser({this.id, required this.email, required this.password});

  Map<String, Object?> toMap() => {
    'id': id,
    'email': email,
    'password': password,
  };

  static LocalUser fromMap(Map<String, Object?> map) => LocalUser(
    id: map['id'] as int?,
    email: map['email'] as String,
    password: map['password'] as String,
  );
}
