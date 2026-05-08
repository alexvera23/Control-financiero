class Movimiento {
  final int? id;
  final String tipo; // 'Ingreso' o 'Gasto'
  final double cantidad;
  final String descripcion;
  final String fecha; // Formato ISO8601 (YYYY-MM-DD)
  final String metodoPago; // 'Efectivo', 'Tarjeta', 'Transferencia'
  final int categoriaId;
  final int usuarioId;

  // Campo adicional para mostrar el nombre de la categoría (JOIN)
  final String? categoriaNombre;
  final String? categoriaColor;
  final String? categoriaIcono;

  Movimiento({
    this.id,
    required this.tipo,
    required this.cantidad,
    required this.descripcion,
    required this.fecha,
    required this.metodoPago,
    required this.categoriaId,
    required this.usuarioId,
    this.categoriaNombre,
    this.categoriaColor,
    this.categoriaIcono,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tipo': tipo,
      'cantidad': cantidad,
      'descripcion': descripcion,
      'fecha': fecha,
      'metodo_pago': metodoPago,
      'categoria_id': categoriaId,
      'usuario_id': usuarioId,
    };
  }

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'] as int?,
      tipo: map['tipo'] as String,
      cantidad: (map['cantidad'] as num).toDouble(),
      descripcion: map['descripcion'] as String,
      fecha: map['fecha'] as String,
      metodoPago: map['metodo_pago'] as String,
      categoriaId: map['categoria_id'] as int,
      usuarioId: map['usuario_id'] as int,
      categoriaNombre: map['categoria_nombre'] as String?,
      categoriaColor: map['color'] as String?,
      categoriaIcono: map['icono'] as String?,
    );
  }

  Movimiento copyWith({
    int? id,
    String? tipo,
    double? cantidad,
    String? descripcion,
    String? fecha,
    String? metodoPago,
    int? categoriaId,
    int? usuarioId,
  }) {
    return Movimiento(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      metodoPago: metodoPago ?? this.metodoPago,
      categoriaId: categoriaId ?? this.categoriaId,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}