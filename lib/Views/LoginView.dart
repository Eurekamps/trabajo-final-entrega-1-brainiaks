import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Statics/DataHolder.dart';


class LoginView extends StatefulWidget {
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController tecUser = TextEditingController();
  TextEditingController tecPass = TextEditingController();
  String errorMessage = '';
  bool _isPasswordVisible = false; // Variable para controlar la visibilidad de la contraseña

  void clickLog() async {

    await DataHolder().fbAdmin.logIn( email: tecUser.text, password: tecPass.text);

    if (DataHolder().userProfile == null) {
      // Si no existe perfil, redirige al ProfileUserView
      Navigator.of(context).pushReplacementNamed("/ProfileUserView");
    } else {
      // Si el perfil existe, navega a la siguiente pantalla
      Navigator.of(context).pushReplacementNamed(
        "/HomeView",
        arguments: DataHolder().userProfile,
      );
    }

    /*try {
      // Autentica al usuario
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: tecUser.text,
        password: tecPass.text,
      );

      // Obtén el UID del usuario autenticado
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        // Llama al método de DataHolder para descargar el perfil
        await DataHolder().getUserProfile(userId);

        // Verifica si el perfil existe
        if (DataHolder().userProfile == null) {
          // Si no existe perfil, redirige al ProfileUserView
          Navigator.of(context).pushReplacementNamed("/ProfileUserView");
        } else {
          // Si el perfil existe, navega a la siguiente pantalla
          Navigator.of(context).pushReplacementNamed(
            "/HomeView",
            arguments: DataHolder().userProfile,
          );
        }
      } else {
        setState(() {
          errorMessage = 'No se encontró el usuario.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Error al iniciar sesión.';
      });
    }*/
  }

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
          "Login - Premios CELO",
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
                obscureText: !_isPasswordVisible, // Controla la visibilidad
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
                        _isPasswordVisible = !_isPasswordVisible; // Alterna la visibilidad
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
                    onPressed: clickLog,
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