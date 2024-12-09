import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triboo/Statics/FirebaseAdmin.dart';


import '../FBObjects/FbCommunity.dart';
import '../FBObjects/FbPerfil.dart';

class DataHolder {
  static final DataHolder _dataHolder = DataHolder._internal();
  // lista de comunidades
  List<FbCommunity> _communities = [];

  FbPerfil? userProfile;
  FirebaseAdmin fbAdmin = FirebaseAdmin();

  // Constructor privado
  DataHolder._internal();

  // Factory constructor para obtener la única instancia de DataHolder
  factory DataHolder() {
    return _dataHolder;
  }

  // Método para obtener el perfil de usuario desde Firestore
  Future<bool> getUserProfile(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        userProfile = FbPerfil.fromFirestore(snapshot, null);
        print("Perfil cargado: ${userProfile.toString()}");
        return true;
      } else {
        print("Perfil de usuario no encontrado en Firestore.");
        userProfile = null;
        return false;
      }
    } catch (e) {
      print("Error al obtener el perfil: $e");
      userProfile = null;
      return false;
    }
  }

  // Método para guardar el perfil del usuario y usar un callback para manejar el error
  Future<void> saveUserProfile(FbPerfil perfil, String s, Function(String) onError) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(perfil.toFirestore());
      }
    } catch (e) {
      onError('Error al guardar el perfil: $e');
    }
  }
  // metodos para las comunidades

  //obtener lista de comunidades
  List<FbCommunity> get communities => _communities;

  //reemplazar lista de comunidades
  set communities(List<FbCommunity> value){
    _communities = value;
  }

  // agregar comunidades
  void addCommunities(FbCommunity communities){
    _communities.add(communities);
  }
  // Actualizar una comunidad existente
  void updateCommunity(FbCommunity communities) {
    final index = _communities.indexWhere((c) => c.id == communities.id);
    if (index != -1) {
      _communities[index] = communities;
    }
  }
  // Eliminar una comunidad por ID
  void deleteCommunity(String id) {
    _communities.removeWhere((c) => c.id == id);
  }
  // Obtener una comunidad específica por ID
  FbCommunity? getCommunityById(String id) {
    try {
      return _communities.firstWhere(
            (c) => c.id == id, // Condición para buscar la comunidad
      );
    } catch (e) {
      return null; // Si no se encuentra, se captura la excepción y devuelve null
    }
  }
  // Sincronizar comunidades desde Firebase
  Future<void> sincronizarComunidades(List<FbCommunity> communitiesFirebase) async {
    _communities = communitiesFirebase;
  }
}
