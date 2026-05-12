import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/categoria.dart';

class PresupuestosScreen extends StatefulWidget {
  final int usuarioId;
  const PresupuestosScreen({super.key, required this.usuarioId});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  late List<Map<String, dynamic>> _presupuestos = [];
  List<Categoria> _categorias = [];
  bool _cargando = true;

  late DateTime _fechaSeleccionada;
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateTime.now();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final cats = await DatabaseHelper.instance.getCategorias(
        widget.usuarioId,
      );
      final presupuestos = await DatabaseHelper.instance.getPresupuestos(
        widget.usuarioId,
        mes: _fechaSeleccionada.month,
        anio: _fechaSeleccionada.year,
      );
      setState(() {
        _categorias = cats;
        _presupuestos = presupuestos;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarDialogoPresupuesto({
    Map<String, dynamic>? presupuestoExistente,
  }) async {
    final montoCtrl = TextEditingController(
      text: presupuestoExistente?['monto']?.toString() ?? '',
    );
    Categoria? categoriaSeleccionada;
    int mesSeleccionado =
        presupuestoExistente?['mes'] ?? _fechaSeleccionada.month;
    int anioSeleccionado =
        presupuestoExistente?['anio'] ?? _fechaSeleccionada.year;

    if (presupuestoExistente != null && _categorias.isNotEmpty) {
      categoriaSeleccionada = _categorias.firstWhere(
        (c) => c.id == presupuestoExistente['categoria_id'],
        orElse: () => _categorias.first,
      );
    } else if (_categorias.isNotEmpty) {
      categoriaSeleccionada = _categorias.first;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(
            presupuestoExistente == null
                ? 'Nuevo Presupuesto'
                : 'Editar Presupuesto',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Categoria>(
                  initialValue: categoriaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: _categorias.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c.nombre));
                  }).toList(),
                  onChanged: (c) =>
                      setModalState(() => categoriaSeleccionada = c),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: mesSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Mes',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (m) =>
                                  DropdownMenuItem(value: m, child: Text('$m')),
                            )
                            .toList(),
                        onChanged: (m) =>
                            setModalState(() => mesSeleccionado = m!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: anioSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            List.generate(5, (i) => DateTime.now().year - 2 + i)
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a,
                                    child: Text('$a'),
                                  ),
                                )
                                .toList(),
                        onChanged: (a) =>
                            setModalState(() => anioSeleccionado = a!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final monto = double.tryParse(montoCtrl.text);
                if (categoriaSeleccionada == null || monto == null) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Completa todos los campos'),
                      ),
                    );
                  }
                  return;
                }

                final presupuestoData = {
                  'monto': monto,
                  'mes': mesSeleccionado,
                  'anio': anioSeleccionado,
                  'categoria_id': categoriaSeleccionada?.id ?? 0,
                  'usuario_id': widget.usuarioId,
                };

                try {
                  if (presupuestoExistente == null) {
                    await DatabaseHelper.instance.insertarPresupuesto(
                      presupuestoData,
                    );
                  } else {
                    presupuestoData['id'] = presupuestoExistente['id'];
                    await DatabaseHelper.instance.actualizarPresupuesto(
                      presupuestoData,
                    );
                  }

                  if (ctx.mounted) Navigator.pop(ctx);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          presupuestoExistente == null
                              ? 'Presupuesto creado'
                              : 'Presupuesto actualizado',
                        ),
                      ),
                    );
                    await _cargarDatos();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(presupuestoExistente == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarPresupuesto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: const Text('¿Estás seguro de eliminar este presupuesto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await DatabaseHelper.instance.eliminarPresupuesto(id);
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Presupuesto eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _presupuestos.isEmpty
          ? const Center(child: Text('No hay presupuestos para este mes'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _presupuestos.length,
              itemBuilder: (_, i) {
                final p = _presupuestos[i];
                final monto = (p['monto'] as num).toDouble();

                return FutureBuilder<double>(
                  future: DatabaseHelper.instance.getGastoActualCategoria(
                    widget.usuarioId,
                    p['categoria_id'] as int,
                    p['mes'] as int,
                    p['anio'] as int,
                  ),
                  builder: (context, snapshot) {
                    final gastoActual = snapshot.data ?? 0.0;
                    final restante = monto - gastoActual;
                    final porcentaje = (gastoActual / monto * 100).clamp(
                      0,
                      100,
                    );
                    final superado = gastoActual > monto;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  p['categoria_nombre'] ?? 'Categoría',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (superado)
                                  const Chip(
                                    label: Text('¡Superado!'),
                                    backgroundColor: Colors.red,
                                    labelStyle: TextStyle(color: Colors.white),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (porcentaje / 100).clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                superado ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gasto: ${_currencyFormat.format(gastoActual)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Restante: ${_currencyFormat.format(restante)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'editar') {
                                      _mostrarDialogoPresupuesto(
                                        presupuestoExistente: p,
                                      );
                                    } else if (value == 'eliminar') {
                                      _eliminarPresupuesto(p['id'] as int);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Text('Editar'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'eliminar',
                                      child: Text('Eliminar'),
                                    ),
                                  ],
                                ),
                                Text(
                                  _currencyFormat.format(monto),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoPresupuesto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
