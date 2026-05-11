import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';

class EstadisticasScreen extends StatelessWidget {
  final int usuarioId;
  const EstadisticasScreen({super.key, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Estadísticas Financieras")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TAB 1: Gastos por Categoría
            const Text(
              'Distribución de Gastos por Categoría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGastosPorCategoria(),
            const SizedBox(height: 32),

            // TAB 2: Ingresos vs Gastos
            const Text(
              'Ingresos vs Gastos - Últimos Meses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildIngresosVsGastos(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGastosPorCategoria() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getGastosPorCategoria(usuarioId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay datos para mostrar"));
        }

        final datos = snapshot.data!;

        return Column(
          children: [
            // Pie Chart
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: datos.map((cat) {
                    final colorString = (cat['color'] as String).replaceAll(
                      '#',
                      '',
                    );
                    return PieChartSectionData(
                      value: cat['total'].toDouble(),
                      title: '${cat['nombre']}',
                      color: Color(int.parse('FF$colorString', radix: 16)),
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Detailed list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: datos.length,
              itemBuilder: (context, index) {
                final item = datos[index];
                final itemColorString = (item['color'] as String).replaceAll(
                  '#',
                  '',
                );
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse('FF$itemColorString', radix: 16),
                    ),
                  ),
                  title: Text(item['nombre']),
                  trailing: Text(
                    "\$${item['total'].toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildIngresosVsGastos() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getEvolucionMensual(usuarioId, meses: 6),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay datos para mostrar"));
        }

        final datos = snapshot.data!;
        final dateFormat = DateFormat('MMM');

        return Column(
          children: [
            // Bar Chart
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: datos
                      .fold<double>(
                        0,
                        (max, item) =>
                            [
                                  item['ingresos'] as double,
                                  item['gastos'] as double,
                                ].reduce((a, b) => a > b ? a : b) >
                                max
                            ? [
                                item['ingresos'] as double,
                                item['gastos'] as double,
                              ].reduce((a, b) => a > b ? a : b)
                            : max,
                      )
                      .toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < datos.length) {
                            final fecha = DateTime(
                              datos[index]['anio'] as int,
                              datos[index]['mes'] as int,
                            );
                            return Text(dateFormat.format(fecha));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(datos.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: datos[index]['ingresos'] as double,
                          color: Colors.green,
                          width: 6,
                        ),
                        BarChartRodData(
                          toY: datos[index]['gastos'] as double,
                          color: Colors.red,
                          width: 6,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 12, height: 12, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Ingresos'),
                const SizedBox(width: 24),
                Container(width: 12, height: 12, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Gastos'),
              ],
            ),
            const SizedBox(height: 16),
            // Summary table
            Table(
              defaultColumnWidth: const FlexColumnWidth(1),
              border: TableBorder.all(color: Colors.grey[300]!),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Mes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Ingresos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Gastos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Balance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...datos.map((d) {
                  final ingresos = d['ingresos'] as double;
                  final gastos = d['gastos'] as double;
                  final balance = ingresos - gastos;
                  final fecha = DateTime(d['anio'] as int, d['mes'] as int);
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(DateFormat('MMM yyyy').format(fecha)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '\$$ingresos',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '\$$gastos',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '\$$balance',
                          style: TextStyle(
                            color: balance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        );
      },
    );
  }
}
