
import 'package:flutter/material.dart';


class Triboo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    // Hay que definir un array de rutas
    Map<String,Widget Function(BuildContext)> rutasNavegacion = {
      '/SplashView':(context)=> SplashView(),
      '/LoginView':(context)=> LoginView(),
      '/HomeView':(context)=>  HomeView(),
      '/MainView':(context)=> MainView(),
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