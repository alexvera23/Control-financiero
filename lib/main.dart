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

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Financiero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Si el usuario ya está logueado, lo mandamos al Dashboard (cuando exista)
      // Por ahora, si no está logueado, la ruta inicial es el login
      initialRoute: isLoggedIn ? '/dashboard' : '/login',
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Define aquí la ruta del dashboard del Integrante 2
        '/dashboard': (context) => const Scaffold(
              body: Center(child: Text('Dashboard en construcción')),
            ),
      },
    );
  }
}