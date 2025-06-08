import 'package:cloud_firestore/cloud_firestore.dart';

class FBPost {
  String id;
  String texto;
  String? imagenURL;
  DateTime fechaCreacion;
  final String comunidadID;
  final String autorID;
  final String autorApodo;
  final String? autorImagenURL;
  final List<String> tags;
  int reportes; // Contador de reportes
  int likes; // Contador de likes
  List<String> likedBy; // Lista de los UID de los usuarios que han dado like
  List<String> reportedBy;

  FBPost({
    required this.id,
    required this.texto,
    this.imagenURL,
    required this.fechaCreacion,
    required this.comunidadID,
    required this.autorID,
    required this.autorApodo,
    this.autorImagenURL,
    this.tags = const [],
    this.reportes = 0, // Inicializa el contador de reportes
    this.likes = 0, // Inicializa el contador de likes
    this.likedBy = const [], // Inicializa la lista de usuarios que dieron like
    this.reportedBy = const [],
  });

  factory FBPost.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();

    // Extraer el ID de la comunidad desde la ruta del documento
    final pathSegments = snapshot.reference.path.split("/");
    String comunidadID = pathSegments.length >= 2 ? pathSegments[1] : '';

    return FBPost(
      id: snapshot.id,
      texto: data?['texto'] ?? '',
      imagenURL: data?['imagenURL'],
      fechaCreacion: (data?['fechaCreacion'] as Timestamp).toDate(),
      autorID: data?['autorID'] ?? '',
      autorApodo: data?['autorApodo'] ?? 'Anónimo',
      autorImagenURL: data?['autorImagenURL'],
      tags: List<String>.from(data?['tags'] ?? []),
      reportes: data?['reportes'] ?? 0,
      likes: data?['likes'] ?? 0,
      likedBy: List<String>.from(data?['likedBy'] ?? []),
      reportedBy: List<String>.from(data?['reportedBy'] ?? []),
      comunidadID: comunidadID, // obtenido del path
    );
  }


  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'imagenURL': imagenURL,
      'fechaCreacion': fechaCreacion,
      'autorID': autorID,
      'autorApodo': autorApodo,
      'autorImagenURL': autorImagenURL,
      'tags': tags,
      'reportes': reportes, // Guardamos los reportes
      'likes': likes, // Guardamos los likes
      'likedBy': likedBy, // Guardamos la lista de usuarios que dieron like
      'reportedBy': reportedBy,
    };
  }
}
