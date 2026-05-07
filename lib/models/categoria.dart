class Categoria {
  final int? id;
  final String nombre;
  final String color; // Se puede guardar como HexString, ej: '#FF0000'
  final String icono; // Se puede guardar el nombre del icono, ej: 'fastfood'
  final int usuarioId;

  Categoria({
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

  Categoria copyWith({
    int? id,
    String? nombre,
    String? color,
    String? icono,
    int? usuarioId,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
      icono: icono ?? this.icono,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'],
      color: map['color'],
      icono: map['icono'],
      usuarioId: map['usuario_id'],
    );
  }
}