import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/categoria.dart';
import '../../models/movimientos.dart';
import 'formulario_movimiento_screen.dart';

class HistorialMovimientosScreen extends StatefulWidget {
  final int usuarioId;
  const HistorialMovimientosScreen({super.key, required this.usuarioId});

  @override
  State<HistorialMovimientosScreen> createState() =>
      _HistorialMovimientosScreenState();
}

class _HistorialMovimientosScreenState
    extends State<HistorialMovimientosScreen> {
  // Datos
  List<Movimiento> _movimientos = [];
  List<Categoria> _categorias = [];
  bool _cargando = true;

  // Filtros activos
  String? _filtroTipo; // null = todos
  Categoria? _filtroCategoria; // null = todas
  DateTime? _filtroDesde;
  DateTime? _filtroHasta;

  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    final movs = await DatabaseHelper.instance.getMovimientos(
      widget.usuarioId,
      tipo: _filtroTipo,
      categoriaId: _filtroCategoria?.id,
      fechaDesde: _filtroDesde != null
          ? DateFormat('yyyy-MM-dd').format(_filtroDesde!)
          : null,
      fechaHasta: _filtroHasta != null
          ? DateFormat('yyyy-MM-dd').format(_filtroHasta!)
          : null,
    );
    final cats = await DatabaseHelper.instance.getCategorias(widget.usuarioId);
    setState(() {
      _movimientos = movs;
      _categorias = cats;
      _cargando = false;
    });
  }

  // ── Navegar al formulario de edición ────────────────────────
  Future<void> _editarMovimiento(Movimiento m) async {
    final hubocambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioMovimientoScreen(
          usuarioId: widget.usuarioId,
          movimientoExistente: m,
        ),
      ),
    );
    if (hubocambio == true) await _cargarTodo();
  }

  // ── Confirmar eliminación ────────────────────────────────────
  Future<void> _eliminarMovimiento(Movimiento m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text('¿Eliminar "${m.descripcion}"?'),
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
      await DatabaseHelper.instance.eliminarMovimiento(m.id!);
      await _cargarTodo();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movimiento eliminado')));
      }
    }
  }

  // ── Hoja de filtros ──────────────────────────────────────────
  Future<void> _abrirFiltros() async {
    String? tipoTmp = _filtroTipo;
    Categoria? catTmp = _filtroCategoria;
    DateTime? desdeTmp = _filtroDesde;
    DateTime? hastaTmp = _filtroHasta;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtrar movimientos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        tipoTmp = null;
                        catTmp = null;
                        desdeTmp = null;
                        hastaTmp = null;
                      });
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const Divider(),

              // Tipo
              const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: [null, 'Ingreso', 'Gasto'].map((t) {
                  return ChoiceChip(
                    label: Text(t ?? 'Todos'),
                    selected: tipoTmp == t,
                    onSelected: (_) => setSheetState(() => tipoTmp = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Categoría
              const Text(
                'Categoría',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              DropdownButton<Categoria?>(
                value: catTmp,
                isExpanded: true,
                hint: const Text('Todas'),
                items: [
                  const DropdownMenuItem<Categoria?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ..._categorias.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c.nombre)),
                  ),
                ],
                onChanged: (c) => setSheetState(() => catTmp = c),
              ),
              const SizedBox(height: 12),

              // Rango de fechas
              const Text(
                'Rango de fechas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        desdeTmp != null
                            ? _dateFormat.format(desdeTmp!)
                            : 'Desde',
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: desdeTmp ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setSheetState(() => desdeTmp = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        hastaTmp != null
                            ? _dateFormat.format(hastaTmp!)
                            : 'Hasta',
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: hastaTmp ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setSheetState(() => hastaTmp = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtroTipo = tipoTmp;
                      _filtroCategoria = catTmp;
                      _filtroDesde = desdeTmp;
                      _filtroHasta = hastaTmp;
                    });
                    Navigator.pop(ctx);
                    _cargarTodo();
                  },
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hayFiltrosActivos =>
      _filtroTipo != null ||
      _filtroCategoria != null ||
      _filtroDesde != null ||
      _filtroHasta != null;

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _abrirFiltros,
                tooltip: 'Filtros',
              ),
              if (_hayFiltrosActivos)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(backgroundColor: Colors.red, radius: 5),
                ),
            ],
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _movimientos.isEmpty
          ? _buildEstadoVacio()
          : Column(
              children: [
                if (_hayFiltrosActivos) _buildBannerFiltros(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _movimientos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _MovimientoCard(
                      movimiento: _movimientos[i],
                      currencyFormat: _currencyFormat,
                      dateFormat: _dateFormat,
                      onEditar: () => _editarMovimiento(_movimientos[i]),
                      onEliminar: () => _eliminarMovimiento(_movimientos[i]),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final hubo = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FormularioMovimientoScreen(usuarioId: widget.usuarioId),
            ),
          );
          if (hubo == true) await _cargarTodo();
        },
        child: const Icon(Icons.add),
        tooltip: 'Nuevo movimiento',
      ),
    );
  }

  Widget _buildBannerFiltros() {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Colors.blue),
          const SizedBox(width: 6),
          const Text('Filtros activos', style: TextStyle(color: Colors.blue)),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _filtroTipo = null;
                _filtroCategoria = null;
                _filtroDesde = null;
                _filtroHasta = null;
              });
              _cargarTodo();
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _hayFiltrosActivos
                ? 'Sin resultados para estos filtros'
                : 'Sin movimientos aún',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (!_hayFiltrosActivos)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Toca + para registrar tu primer movimiento'),
            ),
        ],
      ),
    );
  }
}

// ── Card de Movimiento ───────────────────────────────────────
class _MovimientoCard extends StatelessWidget {
  final Movimiento movimiento;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _MovimientoCard({
    required this.movimiento,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onEditar,
    required this.onEliminar,
  });

  Color get _colorTipo =>
      movimiento.tipo == 'Ingreso' ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    final hex = (movimiento.categoriaColor ?? '#607D8B').replaceAll('#', '');
    final categoriaColor = Color(int.parse('FF$hex', radix: 16));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Indicador de categoría
            CircleAvatar(
              backgroundColor: categoriaColor,
              radius: 22,
              child: const Icon(Icons.label, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),

            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movimiento.descripcion,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        movimiento.categoriaNombre ?? 'Sin categoría',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          movimiento.metodoPago,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    dateFormat.format(DateTime.parse(movimiento.fecha)),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // Cantidad + acciones
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${movimiento.tipo == 'Ingreso' ? '+' : '-'}'
                  '${currencyFormat.format(movimiento.cantidad)}',
                  style: TextStyle(
                    color: _colorTipo,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.blue,
                      ),
                      onPressed: onEditar,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Editar',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: onEliminar,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
