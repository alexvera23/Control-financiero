class Category {
  final int? id;
  final String nombre;
  final String color; // Se puede guardar como HexString, ej: '#FF0000'
  final String icono; // Se puede guardar el nombre del icono, ej: 'fastfood'
  final int usuarioId;

  Category({
    this.id,
    required this.nombre,
    required this.color,
    required this.icono,
    required this.usuarioId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'color': color,
      'icono': icono,
      'usuario_id': usuarioId,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      nombre: map['nombre'],
      color: map['color'],
      icono: map['icono'],
      usuarioId: map['usuario_id'],
    );
  }
}