import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../Theme/AppColors.dart';


class RegisterView extends StatefulWidget {
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  TextEditingController tecUser = TextEditingController();
  TextEditingController tecPass = TextEditingController();
  TextEditingController tecConfirmPass = TextEditingController();
  String errorMessage = '';

  bool _isPasswordVisible = false; // Para la visibilidad de la contraseña
  bool _isConfirmPasswordVisible = false; // Para la visibilidad de la confirmación

  void registerUser() async {
    if (tecPass.text != tecConfirmPass.text) {
      setState(() {
        errorMessage = 'Las contraseñas no coinciden.';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: tecUser.text,
        password: tecPass.text,
      );
      Navigator.of(context).pushNamed("/LoginView");
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Error al crear la cuenta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        iconTheme: theme.iconTheme,
        // No texto en AppBar para evitar repetición con logo y título principal
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo de la app
              Transform.translate(
                offset: Offset(0, -40), // ajusta -20 a lo que necesites
                child: Image.asset(
                  'assets/images/triboo.png',
                  height: 180,
                ),
              ),
              Text(
                "Crear cuenta",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email
              _buildTextField(
                context,
                controller: tecUser,
                label: 'Correo electrónico',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),

              // Password
              _buildTextField(
                context,
                controller: tecPass,
                label: 'Contraseña',
                icon: Icons.lock,
                isPassword: true,
                obscure: !_isPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                visible: _isPasswordVisible,
              ),
              const SizedBox(height: 16),

              // Confirmar Password
              _buildTextField(
                context,
                controller: tecConfirmPass,
                label: 'Confirmar Contraseña',
                icon: Icons.lock,
                isPassword: true,
                obscure: !_isConfirmPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                visible: _isConfirmPasswordVisible,
              ),

              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Botón Registrar
              _gradientButton("Registrar", FontAwesomeIcons.userPlus, registerUser),
            ],
          ),
        ),
      ),
    );
  }
}
Widget _buildTextField(
    BuildContext context, {
      required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isPassword = false,
      bool obscure = false,
      bool visible = false,
      VoidCallback? toggleVisibility,
    }) {
  final colorScheme = Theme.of(context).colorScheme;

  return TextFormField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        margin: const EdgeInsets.all(6),
        child: Icon(icon, color: colorScheme.primary),
      ),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(
          visible ? Icons.visibility : Icons.visibility_off,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        onPressed: toggleVisibility,
      )
          : null,
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
    ),
    style: TextStyle(color: colorScheme.onSurface),
  );
}

Widget _gradientButton(String label, IconData icon, VoidCallback onPressed) {
  return Container(
    height: 48,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.accent],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}