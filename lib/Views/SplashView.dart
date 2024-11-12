import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  double dbPorcentaje = 0.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de animación para la rotación de la imagen
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Tiempo para una rotación completa
      vsync: this,
    )..repeat(); // Repite la animación continuamente

    Loading();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void Loading() async {
    while (dbPorcentaje <= 1.0) {
      setState(() {
        dbPorcentaje += 0.05;
      });
      await Future.delayed(Duration(milliseconds: 100));
    }

    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushReplacementNamed("/HomeView");
    } else {
      Navigator.of(context).pushReplacementNamed("/LoginView");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[200], // Fondo color crema
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/triboo.png',
                height: 200,
              ),
              SizedBox(height: 30),
              SizedBox(height: 30),
              Text(
                "Cargando...",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.brown[600],
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: dbPorcentaje,
                minHeight: 8,
                backgroundColor: Colors.brown[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[700]!),
              ),
              SizedBox(height: 20),
              Text(
                "${(dbPorcentaje * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.brown[500],
                ),
              ),
              SizedBox(height: 40),
              // Imagen rotatoria en lugar de CircularProgressIndicator
              RotationTransition(
                turns: _controller,
                child: Image.asset(
                  'assets/images/tomahawk.png',
                  height: 60, // Ajusta el tamaño de la imagen
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}