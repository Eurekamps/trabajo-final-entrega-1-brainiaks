class FbCommunity {

  String id; // UID de la comunidad
  String uidCreator; //UID del creador
  String uidModders; //UID del moderador
  List<String> uidParticipants; // Lista de UIDS de los participantes
  String name; //nombre de la comunidad
  String description; //Descripcion de la comunidad

  FbCommunity({
    required this.id,
    required this.uidCreator,
    required this.uidModders,
    required this.uidParticipants,
    required this.name,
    required this.description
});

  //instancia de FbCommunity
  factory FbCommunity.fromFirestore(Map<String, dynamic> data, String id){
    return FbCommunity(
        id: id,
        uidCreator: data ['uidCreator'],
        uidModders: data ['uidModders'],
        uidParticipants: data ['uidParticipants'],
        name: data ['name'],
        description: data ['description']
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
    };
  }
}