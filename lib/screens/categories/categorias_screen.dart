import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/categoria.dart';
import '../../utils/icon_picker.dart';

class CategoriasScreen extends StatefulWidget {
  final int usuarioId;
  const CategoriasScreen({super.key, required this.usuarioId});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargando = true);
    final lista = await DatabaseHelper.instance.getCategorias(widget.usuarioId);
    setState(() {
      _categorias = lista;
      _cargando = false;
    });
  }

  // ── Diálogo para Crear o Editar ──────────────────────────────
  Future<void> _mostrarDialogoCategoria({Categoria? categoriaExistente}) async {
    final nombreCtrl =
        TextEditingController(text: categoriaExistente?.nombre ?? '');
    String colorSeleccionado = categoriaExistente?.color ?? '#2196F3';
    String iconoSeleccionado = categoriaExistente?.icono ?? 'e318'; // fastfood

    // Paleta de colores predefinidos
    final colores = [
      '#F44336', '#E91E63', '#9C27B0', '#3F51B5',
      '#2196F3', '#00BCD4', '#4CAF50', '#FF9800',
      '#795548', '#607D8B',
    ];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(
            categoriaExistente == null ? 'Nueva Categoría' : 'Editar Categoría',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Selección de Color
                const Text(
                  'Color',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colores.map((hex) {
                    final color = _hexToColor(hex);
                    final seleccionado = colorSeleccionado == hex;
                    return GestureDetector(
                      onTap: () => setModalState(() => colorSeleccionado = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: seleccionado
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: seleccionado
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selección de Icono
                const Text(
                  'Icono',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconosPredefinidos.entries.map((entry) {
                    final seleccionado = iconoSeleccionado == entry.key;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => iconoSeleccionado = entry.key),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: seleccionado
                              ? _hexToColor(colorSeleccionado)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          entry.value,
                          color: seleccionado ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
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
                final nombre = nombreCtrl.text.trim();
                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es obligatorio')),
                  );
                  return;
                }

                if (categoriaExistente == null) {
                  // CREAR
                  final nueva = Categoria(
                    nombre: nombre,
                    color: colorSeleccionado,
                    icono: iconoSeleccionado,
                    usuarioId: widget.usuarioId,
                  );
                  await DatabaseHelper.instance.insertarCategoria(nueva);
                } else {
                  // EDITAR
                  final actualizada = categoriaExistente.copyWith(
                    nombre: nombre,
                    color: colorSeleccionado,
                    icono: iconoSeleccionado,
                  );
                  await DatabaseHelper.instance
                      .actualizarCategoria(actualizada);
                }

                if (ctx.mounted) Navigator.pop(ctx);
                await _cargarCategorias();
              },
              child: Text(categoriaExistente == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmación para Eliminar ───────────────────────────────
  Future<void> _confirmarEliminar(Categoria categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro de eliminar "${categoria.nombre}"?\n\n'
          'También se eliminarán todos sus movimientos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.eliminarCategoria(categoria.id!);
      await _cargarCategorias();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría "${categoria.nombre}" eliminada')),
        );
      }
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCategorias,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? _buildEstadoVacio()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _categorias.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CategoriaCard(
                    categoria: _categorias[i],
                    onEditar: () =>
                        _mostrarDialogoCategoria(categoriaExistente: _categorias[i]),
                    onEliminar: () => _confirmarEliminar(_categorias[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCategoria(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin categorías aún',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text('Toca + para crear tu primera categoría'),
        ],
      ),
    );
  }
}

// ── Widget Card de Categoría ─────────────────────────────────
class _CategoriaCard extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _CategoriaCard({
    required this.categoria,
    required this.onEditar,
    required this.onEliminar,
  });

  Color get _color {
    final h = categoria.color.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  IconData get _icono {
    return iconosPredefinidos[categoria.icono] ?? Icons.label;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color,
          child: Icon(_icono, color: Colors.white),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEditar,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onEliminar,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}