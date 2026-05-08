import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/users.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Llave global para el formulario de registro
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // 1. Validar todos los campos del formulario
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // 2. Crear el objeto User con los datos ingresados
      final newUser = User(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      try {
        // 3. Intentar registrar en la base de datos SQLite
        await DatabaseHelper.instance.registrarUsuario(newUser);

        if (!mounted) return;

        // 4. Mostrar mensaje de éxito y regresar al Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente. ¡Inicia sesión!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context); // Regresa a la pantalla anterior (Login)

      } catch (e) {
        if (!mounted) return;
        // Capturar y mostrar error (ej. Si el correo ya existe)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Crear Cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo de Nombre
                  TextFormField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa tu nombre.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo.';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Ingresa un correo electrónico válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una contraseña.';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de Confirmar Contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma tu contraseña.';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón de Registro
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Registrarse',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}