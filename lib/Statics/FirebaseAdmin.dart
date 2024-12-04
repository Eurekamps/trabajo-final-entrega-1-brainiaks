import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triboo/FBObjects/FbPerfil.dart';

import 'DataHolder.dart';

class FirebaseAdmin{


  late String logInError;

  /// Función que se encarga del logeo en Firebase y uqe descarga el perfil.
  Future<void> logIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        final data = await fetchFBData(collectionPath: 'users', docId: FirebaseAuth.instance.currentUser!.uid);
        if(data != null){
          if (data.exists) {
            DataHolder().userProfile = FbPerfil.fromFirestore(data, null);
          } else {
            print("Perfil de usuario no encontrado en Firestore.");
            DataHolder().userProfile = null;
          }
        }else{
          DataHolder().userProfile = null;
        }
      } catch (e) {
        print("Error al obtener el perfil: $e");
        DataHolder().userProfile = null;
      }
    } on FirebaseAuthException catch (e) {
     logInError = e.message!;
    }
    return ;
  }


  /// Función genérica para obtener datos desde Firestore.
  /// [collectionPath] es la ruta de la colección.
  /// [docId] es opcional para obtener un documento específico.
  Future<DocumentSnapshot<Map<String, dynamic>>?> fetchFBData({
    required String collectionPath,
    required String? docId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      if (docId != null) {
        // Consultar un documento específico
        final documentSnapshot = await firestore.collection(collectionPath).doc(docId).get();
        if (documentSnapshot.exists) {
          return documentSnapshot;
        } else {
          return null; // Si no existe el documento
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
    return null;
  }


}