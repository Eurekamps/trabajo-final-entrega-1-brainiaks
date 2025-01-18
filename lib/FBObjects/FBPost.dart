import 'package:cloud_firestore/cloud_firestore.dart';

class FBPost {
  String texto; // Contenido del texto de la publicación
  String? imagenURL; // URL de la imagen asociada (opcional)
  DateTime fechaCreacion; // Fecha y hora de la creación de la publicación
  final String autorID; // Identificador único del autor de la publicación

  FBPost({
    required this.texto,
    this.imagenURL,
    required this.fechaCreacion,
    required this.autorID,
  });

  /// Constructor para crear una instancia de FBPost desde un documento Firestore
  factory FBPost.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return FBPost(
      texto: data?['texto'] ?? '',
      imagenURL: data?['imagenURL'],
      fechaCreacion: (data?['fechaCreacion'] as Timestamp).toDate(),
      autorID: data?['autorID'] ?? '',
    );
  }

  /// Método para convertir una instancia de FBPost a un mapa compatible con Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'imagenURL': imagenURL,
      'fechaCreacion': fechaCreacion,
      'autorID': autorID,
    };
  }
}
