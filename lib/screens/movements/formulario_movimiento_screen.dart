import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/categoria.dart';
import '../../models/movimiento.dart';

class FormularioMovimientoScreen extends StatefulWidget {
  final int usuarioId;
  final Movimiento? movimientoExistente; // null = crear, not-null = editar

  const FormularioMovimientoScreen({
    super.key,
    required this.usuarioId,
    this.movimientoExistente,
  });

  @override
  State<FormularioMovimientoScreen> createState() =>
      _FormularioMovimientoScreenState();
}

class _FormularioMovimientoScreenState
    extends State<FormularioMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _cantidadCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Estado del formulario
  String _tipo = 'Gasto';
  String _metodoPago = 'Efectivo';
  DateTime _fechaSeleccionada = DateTime.now();
  Categoria? _categoriaSeleccionada;
  List<Categoria> _categorias = [];
  bool _cargando = true;
  bool _guardando = false;

  final List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia'];

  bool get _esEdicion => widget.movimientoExistente != null;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();

    // Si estamos editando, pre-llenar el formulario
    if (_esEdicion) {
      final m = widget.movimientoExistente!;
      _tipo = m.tipo;
      _cantidadCtrl.text = m.cantidad.toString();
      _descripcionCtrl.text = m.descripcion;
      _metodoPago = m.metodoPago;
      _fechaSeleccionada = DateTime.parse(m.fecha);
    }
  }

  Future<void> _cargarCategorias() async {
    final lista = await DatabaseHelper.instance.getCategorias(widget.usuarioId);
    setState(() {
      _categorias = lista;
      if (_esEdicion) {
        _categoriaSeleccionada = lista.firstWhere(
          (c) => c.id == widget.movimientoExistente!.categoriaId,
          orElse: () => lista.first,
        );
      } else if (lista.isNotEmpty) {
        _categoriaSeleccionada = lista.first;
      }
      _cargando = false;
    });
  }

  // ── Selector de fecha ────────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  // ── Guardar movimiento ───────────────────────────────────────
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una categoría')));
      return;
    }

    setState(() => _guardando = true);

    final movimiento = Movimiento(
      id: widget.movimientoExistente?.id,
      tipo: _tipo,
      cantidad: double.parse(_cantidadCtrl.text.trim()),
      descripcion: _descripcionCtrl.text.trim(),
      fecha: DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
      metodoPago: _metodoPago,
      categoriaId: _categoriaSeleccionada!.id!,
      usuarioId: widget.usuarioId,
    );

    if (_esEdicion) {
      await DatabaseHelper.instance.actualizarMovimiento(movimiento);
    } else {
      await DatabaseHelper.instance.insertarMovimiento(movimiento);
    }

    setState(() => _guardando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion ? 'Movimiento actualizado' : 'Movimiento guardado',
          ),
        ),
      );
      Navigator.pop(context, true); // true = hubo cambios
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Movimiento' : 'Nuevo Movimiento'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Tipo: Ingreso / Gasto ──────────────────
                    _buildSelectorTipo(),
                    const SizedBox(height: 20),

                    // ── Cantidad ───────────────────────────────
                    TextFormField(
                      controller: _cantidadCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad *',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa una cantidad';
                        }
                        final n = double.tryParse(v.trim());
                        if (n == null) return 'Número no válido';
                        if (n <= 0) return 'La cantidad debe ser mayor a 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Descripción ────────────────────────────
                    TextFormField(
                      controller: _descripcionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Agrega una descripción'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Categoría ──────────────────────────────
                    _buildDropdownCategorias(),
                    const SizedBox(height: 16),

                    // ── Fecha ──────────────────────────────────
                    _buildSelectorFecha(),
                    const SizedBox(height: 16),

                    // ── Método de pago ─────────────────────────
                    DropdownButtonFormField<String>(
                      value: _metodoPago,
                      decoration: const InputDecoration(
                        labelText: 'Método de pago',
                        border: OutlineInputBorder(),
                      ),
                      items: _metodosPago
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _metodoPago = v!),
                    ),
                    const SizedBox(height: 28),

                    // ── Botón guardar ──────────────────────────
                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _esEdicion ? 'Actualizar' : 'Guardar movimiento',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Widgets auxiliares ───────────────────────────────────────

  Widget _buildSelectorTipo() {
    return Row(
      children: ['Gasto', 'Ingreso'].map((tipo) {
        final seleccionado = _tipo == tipo;
        final color = tipo == 'Ingreso' ? Colors.green : Colors.red;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                tipo,
                style: TextStyle(
                  color: seleccionado ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: seleccionado,
              selectedColor: color,
              onSelected: (_) => setState(() => _tipo = tipo),
              avatar: Icon(
                tipo == 'Ingreso' ? Icons.arrow_upward : Icons.arrow_downward,
                color: seleccionado ? Colors.white : color,
                size: 18,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownCategorias() {
    if (_categorias.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No tienes categorías. Crea una primero.'),
        ),
      );
    }
    return DropdownButtonFormField<Categoria>(
      value: _categoriaSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Categoría *',
        border: OutlineInputBorder(),
      ),
      items: _categorias.map((c) {
        final hex = c.color.replaceAll('#', '');
        final color = Color(int.parse('FF$hex', radix: 16));
        return DropdownMenuItem(
          value: c,
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color, radius: 12),
              const SizedBox(width: 8),
              Text(c.nombre),
            ],
          ),
        );
      }).toList(),
      onChanged: (c) => setState(() => _categoriaSeleccionada = c),
    );
  }

  Widget _buildSelectorFecha() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)),
      ),
    );
  }
}
