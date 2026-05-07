import 'package:flutter/material.dart';

/// Mapa de codepoint (String) → IconData
/// El String es lo que se guarda en SQLite; IconData se usa solo en la UI.
const Map<String, IconData> iconosPredefinidos = {
  'e318': Icons.fastfood, // Comida
  'e53e': Icons.directions_car, // Transporte
  'e8a0': Icons.shopping_cart, // Compras
  'e145': Icons.add_circle, // General
  'e7fd': Icons.person, // Personal
  'e873': Icons.home, // Hogar
  'e226': Icons.local_hospital, // Salud
  'e80c': Icons.school, // Educación
  'e021': Icons.beach_access, // Ocio
  'e1bc': Icons.fitness_center, // Deporte
  'e8cc': Icons.work, // Trabajo
  'e0be': Icons.phone_android, // Tecnología
  'e0af': Icons.pets, // Mascotas
  'e533': Icons.flight, // Viajes
  'e25a': Icons.attach_money, // Finanzas
};
