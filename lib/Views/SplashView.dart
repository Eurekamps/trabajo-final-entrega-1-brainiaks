import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  double dbPorcentaje = 0.0;

  @override
  void initState() {
    super.initState();
    Loading();
  }

  void Loading() async {
    while (dbPorcentaje <= 1.0) {
      setState(() {
        dbPorcentaje += 0.05;
      });
      await Future.delayed(Duration(milliseconds: 100));
    }

    if(FirebaseAuth.instance.currentUser!=null){
      Navigator.of(context).pushReplacementNamed("/HomeView");
    }
    else{
      Navigator.of(context).pushReplacementNamed("/LoginView");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Premios CELO 2024-2025",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Text(
                "Cargando...",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: dbPorcentaje,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
              ),
              SizedBox(height: 20),
              Text(
                "${(dbPorcentaje * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                strokeWidth: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
