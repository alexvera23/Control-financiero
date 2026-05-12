import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/movimiento.dart';
import '../../utils/icon_picker.dart';

/// Pantalla de solo lectura que muestra todos los datos de un movimiento.
/// Requerida por el Módulo 4 del proyecto: "Ver detalle".
class DetalleMovimientoScreen extends StatelessWidget {
  final Movimiento movimiento;

  const DetalleMovimientoScreen({super.key, required this.movimiento});

  Color get _colorTipo =>
      movimiento.tipo == 'Ingreso' ? Colors.green : Colors.red;

  Color get _colorCategoria {
    final hex = (movimiento.categoriaColor ?? '#607D8B').replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData get _iconoCategoria =>
      iconosPredefinidos[movimiento.categoriaIcono] ?? Icons.label;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final fecha = DateFormat(
      'dd \'de\' MMMM \'de\' yyyy',
      'es',
    ).format(DateTime.parse(movimiento.fecha));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tarjeta principal con cantidad y tipo ──────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    // Chip de tipo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _colorTipo.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            movimiento.tipo == 'Ingreso'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: _colorTipo,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            movimiento.tipo,
                            style: TextStyle(
                              color: _colorTipo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cantidad
                    Text(
                      currency.format(movimiento.cantidad),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _colorTipo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Descripción
                    Text(
                      movimiento.descripcion,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Filas de detalle ───────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _FilaDetalle(
                    icono: Icons.calendar_today,
                    etiqueta: 'Fecha',
                    valor: fecha,
                  ),
                  const Divider(height: 1, indent: 56),
                  _FilaDetalle(
                    icono: Icons.payment,
                    etiqueta: 'Método de pago',
                    valor: movimiento.metodoPago,
                  ),
                  const Divider(height: 1, indent: 56),
                  // Categoría con color e icono reales
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _colorCategoria,
                      child: Icon(
                        _iconoCategoria,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Categoría',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      movimiento.categoriaNombre ?? 'Sin categoría',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila auxiliar de detalle ──────────────────────────────────
class _FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaDetalle({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: Colors.grey[600]),
      title: Text(
        etiqueta,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        valor,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }
}
