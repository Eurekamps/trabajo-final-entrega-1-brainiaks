import 'package:cloud_firestore/cloud_firestore.dart';

class FbCommunity {
  String id; // UID de la comunidad
  String uidCreator; // UID del creador
  String uidModders; // UIDs de los moderadores (separados por coma)
  List<String> uidParticipants; // Lista de UIDs de los participantes
  String name; // Nombre de la comunidad
  String description; // Descripción de la comunidad
  String avatar; // URL del avatar
  String category; // Categoría (Deportes, Libros, etc.)
  String? password; // Contraseña opcional

  FbCommunity({
    required this.id,
    required this.uidCreator,
    required this.uidModders,
    required this.uidParticipants,
    required this.name,
    required this.description,
    required this.avatar,
    required this.category,
    this.password,
  });

  factory FbCommunity.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();

    return FbCommunity(
      id: snapshot.id,
      uidCreator: data?['uidCreator'] ?? '',
      uidModders: data?['uidModders'] ?? '',
      uidParticipants: (data?['uidParticipants'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      name: data?['name'] ?? '',
      description: data?['description'] ?? '',
      avatar: data?['avatar'] ?? '',
      category: data?['category'] ?? '',
      password: (data != null && data.containsKey('password'))
          ? data['password'] as String?
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'uidCreator': uidCreator,
      'uidModders': uidModders,
      'uidParticipants': uidParticipants,
      'name': name,
      'description': description,
      'avatar': avatar,
      'category': category,
    };

    if (password != null && password!.isNotEmpty) {
      data['password'] = password as Object;
    }

    return data;
  }
}

