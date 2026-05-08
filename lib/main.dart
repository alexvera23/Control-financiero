import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
// Importa aquí tu pantalla de Dashboard cuando esté lista
// import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de usar SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // Verificamos si ya existe una sesión activa
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  // Leemos el ID del usuario guardado al hacer login
  final int usuarioId = prefs.getInt('usuarioId') ?? 0;

  runApp(MyApp(isLoggedIn: isLoggedIn, usuarioId: usuarioId));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int usuarioId;

  const MyApp({super.key, required this.isLoggedIn, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Financiero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Si el usuario ya tiene sesión activa va al dashboard, si no al login
      initialRoute: isLoggedIn ? '/dashboard' : '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Cuando el integrante 3 entregue el Dashboard, reemplaza este Scaffold
        // por: DashboardScreen(usuarioId: usuarioId)
        '/dashboard': (context) => Scaffold(
              body: Center(
                child: Text('Dashboard en construcción (usuarioId: $usuarioId)'),
              ),
            ),
      },
    );
  }
}