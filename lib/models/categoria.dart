class Categoria {
  final int? id;
  final String nombre;
  final String color; // Hex color ej: '#FF5733'
  final String icono; // Codepoint del icono ej: 'e318' (Icons.fastfood)
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
      if (id != null) 'id': id,
      'nombre': nombre,
      'color': color,
      'icono': icono,
      'usuario_id': usuarioId,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      color: map['color'] as String,
      icono: map['icono'] as String,
      usuarioId: map['usuario_id'] as int,
    );
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
}
