import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../FBObjects/FbPerfil.dart';
import '../Statics/DataHolder.dart';
import '../Statics/FirebaseAdmin.dart';
import 'LoadingView.dart';

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



  // Función para limpiar los campos de entrada y los errores
  void clearFields() {
    tecUser.clear();
    tecPass.clear();
    setState(() {
      errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          "Login - Triboo",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[800],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Inicia sesión",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: tecUser,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                  prefixIcon: Icon(Icons.email, color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: tecPass,
                obscureText: !_isPasswordVisible, // Controla la visibilidad de la contraseña
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                  prefixIcon: Icon(Icons.lock, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible; // Alterna la visibilidad de la contraseña
                      });
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: FaIcon(FontAwesomeIcons.check),
                    label: Text("Login"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: clickLog, // Ahora usa el método clickLog que hace la autenticación
                  ),
                  ElevatedButton.icon(
                    icon: FaIcon(FontAwesomeIcons.times),
                    label: Text("Limpiar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: clearFields,
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed("/RegisterView");
                },
                child: Text(
                  "¿No tienes una cuenta? ¡¡¡Regístrate!!!",
                  style: TextStyle(fontSize: 16, color: Colors.lightBlueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
