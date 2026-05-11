class Budget {
  final int? id;
  final double monto;
  final int mes;
  final int anio;
  final int categoriaId;
  final int usuarioId;

  Budget({
    this.id,
    required this.monto,
    required this.mes,
    required this.anio,
    required this.categoriaId,
    required this.usuarioId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monto': monto,
      'mes': mes,
      'anio': anio,
      'categoria_id': categoriaId,
      'usuario_id': usuarioId,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      monto: (map['monto'] as num).toDouble(),
      mes: map['mes'],
      anio: map['anio'],
      categoriaId: map['categoria_id'],
      usuarioId: map['usuario_id'],
    );
  }
}
