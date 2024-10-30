
import 'package:flutter/material.dart';


class Triboo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    // Hay que definir un array de rutas
    Map<String,Widget Function(BuildContext)> rutasNavegacion = {
    };

    MaterialApp app = MaterialApp(title: "Triboo",
      routes: rutasNavegacion,
      initialRoute: '/',
      debugShowCheckedModeBanner: false, // Oculta el banner de debug
    );
    return app;

  }
}