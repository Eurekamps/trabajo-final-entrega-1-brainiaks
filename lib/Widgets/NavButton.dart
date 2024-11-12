import 'package:flutter/material.dart';

//Esta clase representa a los botones de la barra de navegación

class NavButton extends StatefulWidget{

  final IconData idIcon; //Esto sera el icono que muestre el botton
  final String sDir; //Esto sera la dirección a la que navegara cundo pulses el botton
  
  NavButton({
    required this.idIcon,
    required this.sDir,
    Key? key,
  }) : super(key: key);

  @override
  State<NavButton> createState() => _NavButtonState();
  
}

class _NavButtonState extends State<NavButton> {

  void _navigate() {
    Navigator.pushNamed(context, widget.sDir); // Navega a la ruta especificada
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(widget.idIcon), // Usa el icono pasado
      onPressed: _navigate, // Navega al pulsar
    );
  }
}