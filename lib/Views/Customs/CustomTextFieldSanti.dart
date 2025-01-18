import 'package:flutter/material.dart';

class CustomTextFieldSanti extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData prefixIcon;  // Nuevo parámetro para el ícono

  // Modifica el constructor para aceptar el ícono
  CustomTextFieldSanti({
    required this.label,
    required this.controller,
    this.prefixIcon = Icons.text_fields, // Valor predeterminado si no se pasa un ícono
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF020202)),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white24,
        prefixIcon: Icon(prefixIcon, color: Color(0xFF020202)), // Usamos el ícono proporcionado
      ),
      style: TextStyle(color: Color(0xFF020202)),
    );
  }
}