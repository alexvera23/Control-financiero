import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/movimiento.dart';
import '../../models/categoria.dart';

class RegistroMovimientoScreen extends StatefulWidget {
  final int usuarioId;
  final Movimiento? movimientoEdit; // Para reutilizar en edición

  const RegistroMovimientoScreen({
    super.key,
    required this.usuarioId,
    this.movimientoEdit,
  });

  @override
  State<RegistroMovimientoScreen> createState() =>
      _RegistroMovimientoScreenState();
}

class _RegistroMovimientoScreenState extends State<RegistroMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Campos del formulario
  String _tipo = 'Gasto';
  final _cantidadController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now();
  String _metodoPago = 'Efectivo';
  int? _categoriaId;

  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    // Si estamos editando, cargamos los valores existentes
    if (widget.movimientoEdit != null) {
      _tipo = widget.movimientoEdit!.tipo;
      _cantidadController.text = widget.movimientoEdit!.cantidad.toString();
      _descripcionController.text = widget.movimientoEdit!.descripcion;
      _fechaSeleccionada = DateTime.parse(widget.movimientoEdit!.fecha);
      _metodoPago = widget.movimientoEdit!.metodoPago;
      _categoriaId = widget.movimientoEdit!.categoriaId;
    }
  }

  Future<void> _cargarCategorias() async {
    final cats = await DatabaseHelper.instance.getCategorias(widget.usuarioId);
    setState(() {
      _categorias = cats;
      if (_categoriaId == null && cats.isNotEmpty) {
        _categoriaId = cats.first.id;
      }
    });
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      if (_categoriaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona una categoría')),
        );
        return;
      }

      final mov = Movimiento(
        id: widget.movimientoEdit?.id,
        tipo: _tipo,
        cantidad: double.parse(_cantidadController.text),
        descripcion: _descripcionController.text,
        fecha: DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
        metodoPago: _metodoPago,
        categoriaId: _categoriaId!,
        usuarioId: widget.usuarioId,
      );

      if (widget.movimientoEdit == null) {
        await DatabaseHelper.instance.insertarMovimiento(mov);
      } else {
        await DatabaseHelper.instance.actualizarMovimiento(mov);
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.movimientoEdit == null
              ? 'Nuevo Movimiento'
              : 'Editar Movimiento',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Selector de Tipo (Gasto / Ingreso)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Gasto',
                    label: Text('Gasto'),
                    icon: Icon(Icons.remove_circle),
                  ),
                  ButtonSegment(
                    value: 'Ingreso',
                    label: Text('Ingreso'),
                    icon: Icon(Icons.add_circle),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _tipo = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Campo Cantidad
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa un monto';
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'La cantidad debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector de Categoría
              DropdownButtonFormField<int>(
                initialValue: _categoriaId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.nombre),
                  );
                }).toList(),
                onChanged: (val) => setState(() {
                  _categoriaId = val;
                }),
              ),
              const SizedBox(height: 16),

              // Selector de Fecha
              ListTile(
                title: Text(
                  "Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}",
                ),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaSeleccionada,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaSeleccionada = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Método de Pago
              DropdownButtonFormField<String>(
                initialValue: _metodoPago,
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: ['Efectivo', 'Tarjeta', 'Transferencia'].map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) => setState(() {
                  _metodoPago = val!;
                }),
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tipo == 'Gasto'
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                  ),
                  child: const Text(
                    'GUARDAR MOVIMIENTO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
