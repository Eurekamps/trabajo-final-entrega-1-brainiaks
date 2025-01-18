import 'package:flutter/material.dart';

class CustomButtonSanti extends StatelessWidget {
  final IconData icon;           // Ícono para el botón
  final String label;            // Texto del botón
  final VoidCallback onPressed;  // Acción al presionar
  final Color backgroundColor;   // Color de fondo
  final Color foregroundColor;   // Color del texto y el ícono
  final EdgeInsets padding;      // Espaciado interno
  final double borderRadius;     // Borde redondeado del botón

  const CustomButtonSanti({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF00C4FF), // Color predeterminado
    this.foregroundColor = Colors.black,           // Color de texto/ícono
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 8.0,                       // Radio predeterminado
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: foregroundColor),
      label: Text(
        label,
        style: TextStyle(color: foregroundColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onPressed,
    );
  }
}