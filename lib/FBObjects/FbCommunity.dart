import 'package:cloud_firestore/cloud_firestore.dart';

class FbCommunity {

  String id; // UID de la comunidad
  String uidCreator; //UID del creador
  String uidModders; //UID del moderador
  List<String> uidParticipants; // Lista de UIDS de los participantes
  String name; //nombre de la comunidad
  String description; //Descripcion de la comunidad
  String avatar; // foto de comunidad

  FbCommunity({
    required this.id,
    required this.uidCreator,
    required this.uidModders,
    required this.uidParticipants,
    required this.name,
    required this.description,
    required this.avatar
});

  //instancia de FbCommunity
  factory FbCommunity.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data(); // Obtiene los datos del documento
    return FbCommunity(
      id: snapshot.id, // Accede al ID del documento
      uidCreator: data?['uidCreator'],
      uidModders: data?['uidModders'],
      uidParticipants: data?['uidParticipants'],
      name: data?['name'],
      description: data?['description'],
      avatar: data?['avatar'],
    );
  }

  //Convierte esta instancia a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore(){
    return {
      'uidCreator': uidCreator,
      'uidModders': uidModders,
      'uidParticipants': uidParticipants,
      'name': name,
      'description': description,
      'avatar': avatar
    };
  }
}