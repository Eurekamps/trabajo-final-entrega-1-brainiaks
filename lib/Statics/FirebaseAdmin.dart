import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triboo/FBObjects/FbPerfil.dart';

import 'DataHolder.dart';

class FirebaseAdmin{


  late String logInError;
  late FbPerfil? currentProfile;

  Future<void> logIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        final data = await fetchData(collectionPath: 'users', docId: FirebaseAuth.instance.currentUser?.uid);
        /*final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();*/
        if (data.exists) {
          currentProfile = FbPerfil.fromFirestore(data, null);
        } else {
          print("Perfil de usuario no encontrado en Firestore.");
          currentProfile = null;
        }
      } catch (e) {
        print("Error al obtener el perfil: $e");
        currentProfile = null;
      }
    } on FirebaseAuthException catch (e) {
     logInError = e.message!;
    }
  }


  /// Función genérica para obtener datos desde Firestore.
  /// [collectionPath] es la ruta de la colección.
  /// [docId] es opcional para obtener un documento específico.
  /// [filters] permite agregar filtros (pares campo-valor).
  /// Retorna una lista de Map<String, dynamic> con los datos obtenidos.
  Future fetchData({
    required String collectionPath,
     String? docId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      if (docId != null) {
        // Consultar un documento específico
        final documentSnapshot = await firestore.collection(collectionPath).doc(docId).get();
        if (documentSnapshot.exists) {
          return [documentSnapshot];
        } else {
          return []; // Si no existe el documento
        }
      } else {
        // Consultar una colección
        Query query = firestore.collection(collectionPath);

        // Aplicar filtros, si los hay
        if (filters != null) {
          filters.forEach((key, value) {
            query = query.where(key, isEqualTo: value);
          });
        }

        final querySnapshot = await query.get();

        // Convertir los resultados en una lista de mapas
        return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }


  Future<void> getUserProfile(String userId) async {

  }
}