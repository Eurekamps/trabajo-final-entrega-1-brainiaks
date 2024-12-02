import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../FBObjects/FbPerfil.dart';

class DataHolder {
  static final DataHolder _dataHolder = DataHolder._internal();

  FbPerfil? userProfile;

  // Constructor privado
  DataHolder._internal();

  // Factory constructor para obtener la única instancia de DataHolder
  factory DataHolder() {
    return _dataHolder;
  }

  // Método para obtener el perfil de usuario desde Firestore
  Future<void> getUserProfile(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        userProfile = FbPerfil.fromFirestore(snapshot, null);
      } else {
        print("Perfil de usuario no encontrado en Firestore.");
        userProfile = null;
      }
    } catch (e) {
      print("Error al obtener el perfil: $e");
      userProfile = null;
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
}
