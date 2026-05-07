class Movimiento {
  final int? id;
  final String tipo; // 'Ingreso' o 'Gasto'
  final double cantidad;
  final String descripcion;
  final String fecha; // Formato ISO8601 (YYYY-MM-DD)
  final String metodoPago; // 'Efectivo', 'Tarjeta', 'Transferencia'
  final int categoriaId;
  final int usuarioId;
  final String? categoriaNombre;
  final String? categoriaColor;

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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      id: map['id'],
      tipo: map['tipo'],
      // SQLite a veces retorna enteros aunque sea REAL, por eso forzamos a double
      cantidad: (map['cantidad'] as num).toDouble(), 
      descripcion: map['descripcion'],
      fecha: map['fecha'],
      metodoPago: map['metodo_pago'],
      categoriaId: map['categoria_id'],
      usuarioId: map['usuario_id'],
      categoriaNombre: map['categoria_nombre'],
      categoriaColor: map['color'],
    );
  }
}