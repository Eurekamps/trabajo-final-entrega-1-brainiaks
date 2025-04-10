import 'package:cloud_firestore/cloud_firestore.dart';

class FBPost {
  String texto;
  String? imagenURL;
  DateTime fechaCreacion;
  final String autorID;
  final String autorApodo;
  final List<String> tags;
  //final int comentariosCount;

  FBPost({
    required this.texto,
    this.imagenURL,
    required this.fechaCreacion,
    required this.autorID,
    required this.autorApodo,
    this.tags = const [],
    //this.comentariosCount = 0,
  });

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
      autorApodo: data?['autorApodo'] ?? 'Anónimo',
      tags: List<String>.from(data?['tags'] ?? []),
      //comentariosCount: data?['comentariosCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'imagenURL': imagenURL,
      'fechaCreacion': fechaCreacion,
      'autorID': autorID,
      'autorApodo': autorApodo,
      'tags': tags,
      //'comentariosCount': comentariosCount,
    };
  }
}