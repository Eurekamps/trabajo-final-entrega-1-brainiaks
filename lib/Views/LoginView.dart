import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../FBObjects/FbPerfil.dart';
import '../Statics/DataHolder.dart';
import '../Statics/FirebaseAdmin.dart';
import '../Theme/AppColors.dart';
import 'LoadingView.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginView extends StatefulWidget {
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController tecUser = TextEditingController();
  TextEditingController tecPass = TextEditingController();
  String errorMessage = '';
  bool _isPasswordVisible = false;

  // Método que se invoca cuando el usuario hace clic en el botón de login
  void clickLog() async {
    try {
      // Validar que los campos no estén vacíos
      if (tecUser.text.isEmpty || tecPass.text.isEmpty) {
        setState(() => errorMessage = 'Complete todos los campos');
        return;
      }

      // Limpiar perfil previo antes de autenticar al usuario
      DataHolder().userProfile = null;

      // Usamos el método logIn de FirebaseAdmin para autenticar y obtener el perfil
      await FirebaseAdmin().logIn(
        email: tecUser.text.trim(),
        password: tecPass.text.trim(),
        onError: (error) {
          setState(() => errorMessage = error);
        },
      );

      // Imprimir si la autenticación fue exitosa
      print("Autenticación exitosa, usuario con UID: ${FirebaseAuth.instance.currentUser?.uid}");

      // Verificar si el perfil existe (ya está en DataHolder)
      if (DataHolder().userProfile != null) {
        // Si el perfil existe, imprimir los datos del perfil
        final userProfile = DataHolder().userProfile;
        print("Perfil cargado exitosamente desde Firestore.");
        print("Datos del perfil:");
        print("Nombre: ${userProfile?.nombre}");
        print("Apodo: ${userProfile?.apodo}");
        print("Fecha de cumpleaños: ${userProfile?.cumple}");
        print("URL de la imagen: ${userProfile?.imagenURL}");

        // Redirigir a la vista principal
        Navigator.pushReplacementNamed(context, "/HomeView");
      } else {
        // Si no existe el perfil, redirigir a la vista para completar el perfil
        print("No se encontró el perfil del usuario, redirigiendo a completar perfil.");
        Navigator.pushReplacementNamed(context, "/ProfileUserView");
      }
    } catch (e) {
      // Manejar cualquier excepción
      print("Error inesperado durante login: ${e.toString()}");
      setState(() => errorMessage = 'Error inesperado: ${e.toString()}');
    }
  }

  // Login con Google
  Future<void> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // 🖥️ WEB: usar signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // 📱 ANDROID / iOS: usar GoogleSignIn normal
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => errorMessage = "Login cancelado por el usuario");
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final uid = userCredential.user?.uid;
      print("✅ Google login UID: $uid");

      // Intentar cargar perfil desde Firestore
      await FirebaseAdmin().loadUserProfile(
        uid: uid!,
        onError: (error) => setState(() => errorMessage = error),
      );

      if (DataHolder().userProfile != null) {
        Navigator.pushReplacementNamed(context, "/HomeView");
      } else {
        Navigator.pushReplacementNamed(context, "/ProfileUserView");
      }
    } on FirebaseAuthException catch (e) {
      print("🔥 FirebaseAuthException: ${e.code} - ${e.message}");
      setState(() => errorMessage = "Error: ${e.message}");
    } catch (e) {
      print("❌ Error general durante login con Google: $e");
      setState(() => errorMessage = "Error al iniciar sesión con Google");
    }
  }



  // Función para limpiar los campos de entrada y los errores
  void clearFields() {
    tecUser.clear();
    tecPass.clear();
    setState(() {
      errorMessage = '';
    });
  }



  void resetPassword(BuildContext context) async {
    if (tecUser.text.isEmpty || !tecUser.text.contains('@')) {
      setState(() {
        errorMessage = 'Introduce tu correo para recuperar la contraseña.';
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: tecUser.text.trim());

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Correo enviado'),
          content: Text('Hemos enviado un enlace de recuperación a tu correo electrónico.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("🔐 Error al recuperar contraseña: ${e.code} - ${e.message}");
      setState(() {
        errorMessage = 'Error: ${e.message}';
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
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo opcional, puedes quitarlo si no se usa aquí
              Transform.translate(
                offset: Offset(0, -40),
                child: Image.asset(
                  'assets/images/triboo.png',
                  height: 180,
                ),
              ),

              Text(
                "Inicia sesión",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              _buildTextField(
                context,
                controller: tecUser,
                label: 'Correo electrónico',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
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

              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => resetPassword(context),
                  child: Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _gradientButton("Login", FontAwesomeIcons.signInAlt, clickLog),
                  const SizedBox(width: 16),
                  _outlineButton("Limpiar", FontAwesomeIcons.times, clearFields),
                ],
              ),

              const SizedBox(height: 24),

// Botón Login con Google con estilo igual al _gradientButton pero sin Expanded
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: signInWithGoogle,
                    icon: FaIcon(FontAwesomeIcons.google, size: 16),
                    label: const Text("Login con Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),


              TextButton(
                onPressed: () => Navigator.of(context).pushNamed("/RegisterView"),
                child: Text(
                  "¿No tienes una cuenta? ¡¡¡Regístrate!!!",
                  style: TextStyle(fontSize: 16, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return Expanded(
      child: Container(
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
              offset: Offset(0, 4),
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
      ),
    );
  }

  Widget _outlineButton(String label, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}