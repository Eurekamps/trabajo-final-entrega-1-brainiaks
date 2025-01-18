import 'package:cloud_firestore/cloud_firestore.dart';

class FbPerfil {

  String apodo;
  String imagenURL;
  String nombre;
  String cumple;

  FbPerfil({
    required this.nombre,
    required this.apodo,
    required this.imagenURL,
    required this.cumple,
  });

  factory FbPerfil.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return FbPerfil(
      nombre: data?['nombre'] ,
      apodo: data?['apodo'],
      imagenURL:data?['imagenURL'],
      cumple: data?['cumpleaños'] ?? '',
    );
  }


  Map<String, dynamic> toFirestore() {
    return {
      "nombre": nombre,
      "imagenURL": imagenURL,
      "apodo": apodo,
      "cumpleaños": cumple,
    };
  }
}