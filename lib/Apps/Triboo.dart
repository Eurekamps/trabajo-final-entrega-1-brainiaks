
import 'package:flutter/material.dart';
import 'package:triboo/Views/HomeView.dart';
import 'package:triboo/Views/LoginView.dart';
import 'package:triboo/Views/ProfileUserView.dart';
import 'package:triboo/Views/RegisterView.dart';
import 'package:triboo/Views/SplashView.dart';


class Triboo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    // Hay que definir un array de rutas
    Map<String,Widget Function(BuildContext)> rutasNavegacion ={
      '/SplashView':(context)=> SplashView(),
      '/LoginView':(context)=> LoginView(),
      '/HomeView':(context)=>  HomeView(),
      '/RegisterView':(context) => RegisterView(),
      '/ProfileUserView':(context) => ProfileUserView(),
    };

    MaterialApp app = MaterialApp(title: "Triboo",
      routes: rutasNavegacion,
      initialRoute: '/SplashView',
      debugShowCheckedModeBanner: false, // Oculta el banner de debug
    );
    return app;

  }
}