import 'package:cloud_firestore/cloud_firestore.dart';

class FBComentario {
  final String id;
  final String texto;
  final String autorID;
  final String autorApodo;
  final String? autorImagenURL;
  final DateTime fechaCreacion;

  FBComentario({
    required this.id,
    required this.texto,
    required this.autorID,
    required this.autorApodo,
    this.autorImagenURL,
    required this.fechaCreacion,
  });

  factory FBComentario.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options) {
    final data = snapshot.data()!;
    return FBComentario(
      id: snapshot.id,
      texto: data['texto'] ?? '',
      autorID: data['autorID'] ?? '',
      autorApodo: data['autorApodo'] ?? 'Anónimo',
      autorImagenURL: data['autorImagenURL'],
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'autorID': autorID,
      'autorApodo': autorApodo,
      'autorImagenURL': autorImagenURL,
      'fechaCreacion': fechaCreacion,
    };
  }
}
