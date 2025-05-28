import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:triboo/FBObjects/FbPerfil.dart';
import 'package:triboo/Statics/DataHolder.dart';

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

    FirebaseAuth.instance.authStateChanges().first.then((user) async {
      if (user != null) {
        await _loadUser();
      } else {
        Navigator.of(context).pushReplacementNamed("/LoginView");
      }
    }).catchError((e) {
      print("Error detecting auth state: $e");
      Navigator.of(context).pushReplacementNamed("/LoginView");
    });

  }

  Future<void> _loadUser() async{

    final snapshot = await DataHolder().fbAdmin.fetchFBData(collectionPath: "users", docId: FirebaseAuth.instance.currentUser!.uid);

    if(snapshot != null){
      DataHolder().userProfile = FbPerfil.fromFirestore(snapshot, null);
      Navigator.of(context).pushReplacementNamed("/HomeView");
    }else{
      Navigator.of(context).pushReplacementNamed("/LoginView");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/triboo.png',
                height: 180,
              ),
              const SizedBox(height: 30),
              Text(
                "Cargando...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: dbPorcentaje,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                "${(dbPorcentaje * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 40),
              RotationTransition(
                turns: _controller,
                child: Image.asset(
                  'assets/images/tomahawk.png',
                  height: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}