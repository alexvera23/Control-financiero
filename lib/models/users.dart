class User {
  final int? id;
  final String nombre;
  final String email;
  final String password;

  User({
    this.id,
    required this.nombre,
    required this.email,
    required this.password,
  });

  // Convierte un objeto User en un Map para insertarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'password': password,
    };
  }

  // Crea un objeto User a partir de un Map obtenido de SQLite
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nombre: map['nombre'],
      email: map['email'],
      password: map['password'],
    );
  }
}