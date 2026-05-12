import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  final int usuarioId;
  const DashboardScreen({super.key, required this.usuarioId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Función para refrescar los datos cuando volvemos de otra pantalla
  void _refresh() {
    setState(() {});
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('usuarioId');
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Financiero'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, double>>(
        // Llamamos a la función que agregamos al DatabaseHelper
        future: DatabaseHelper.instance.getResumenMensual(widget.usuarioId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final datos =
              snapshot.data ?? {'ingresos': 0.0, 'gastos': 0.0, 'balance': 0.0};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resumen del Mes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 1. CARD DE BALANCE PRINCIPAL
                _buildBalanceCard(datos['balance']!),

                const SizedBox(height: 16),

                // 2. FILA DE INGRESOS Y GASTOS
                Row(
                  children: [
                    _buildStatCard(
                      "Ingresos",
                      datos['ingresos']!,
                      Colors.green,
                      Icons.arrow_upward,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Gastos",
                      datos['gastos']!,
                      Colors.red,
                      Icons.arrow_downward,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const Text(
                  "Accesos Rápidos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // 3. MENÚ DE NAVEGACIÓN (GRILLA)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildMenuItem(
                      context,
                      Icons.list_alt,
                      "Historial",
                      "/historial",
                      Colors.blue,
                    ),
                    _buildMenuItem(
                      context,
                      Icons.category,
                      "Categorías",
                      "/categorias",
                      Colors.orange,
                    ),
                    _buildMenuItem(
                      context,
                      Icons.pie_chart,
                      "Estadísticas",
                      "/estadisticas",
                      Colors.teal,
                    ),
                    _buildMenuItem(
                      context,
                      Icons.account_balance_wallet,
                      "Presupuestos",
                      "/presupuestos",
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      // BOTÓN FLOTANTE PARA REGISTRAR MOVIMIENTO (Módulo 3)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/registro_movimiento');
          _refresh(); // Refrescar al volver
        },
        label: const Text("Nuevo"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // Widget para la Card de Balance
  Widget _buildBalanceCard(double monto) {
    return Card(
      elevation: 8,
      shadowColor: Colors.blue.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.blueAccent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: [
            const Text(
              "Balance Total",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "\$${monto.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para las Cards de Ingresos/Gastos
  Widget _buildStatCard(
    String titulo,
    double monto,
    Color color,
    IconData icono,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "\$${monto.toStringAsFixed(2)}",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para los botones del menú
  Widget _buildMenuItem(
    BuildContext context,
    IconData icono,
    String texto,
    String ruta,
    Color color,
  ) {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, ruta);
        _refresh();
      },
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
