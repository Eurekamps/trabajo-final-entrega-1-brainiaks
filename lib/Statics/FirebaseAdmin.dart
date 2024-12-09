import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triboo/FBObjects/FbCommunity.dart';
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

  //Sincronizar comunidades con Firebase
  Future<void> syncCommunities() async {
    try {
      // Obtener todas las comunidades como documentos de Firestore
      List<DocumentSnapshot<Map<String, dynamic>>>? communitiesSnapshot = await fetchFBDataList(
        collectionPath: 'comunidades',
      );
      // Si se obtienen documentos, convertirlos a una lista de FbCommunity
      if (communitiesSnapshot != null) {
        List<FbCommunity> communities = communitiesSnapshot
            .map((doc) => FbCommunity.fromFirestore(doc))
            .toList();
        // Sincronizar las comunidades con el DataHolder
        DataHolder().syncCommunities(communities);
      }
    } catch (e) {
      print("Error al sincronizar comunidades desde Firebase: $e");
    }
  }
  //agregar una nueva comunidad
  Future<void> addCommunity(FbCommunity community) async{
    try{
      await saveFBData(
        collectionPath: 'communities',
        data: community.toFirestore(),
      );
      print("Community added successfully");
      DataHolder().addCommunities(community);
    }catch (e){
      print("Error adding community: $e");
    }
  }

  // Actualizar una comunidad existente en Firestore y en el DataHolder
  Future<void> updateCommunity(FbCommunity community) async {
    try {
      await saveFBData(
        collectionPath: 'communities',
        data: community.toFirestore(),
        docId: community.id,  // Usamos el id para actualizar
      );
      print("Community updated successfully");
      DataHolder().updateCommunity(community);
    } catch (e) {
      print("Error updating community: $e");
    }
  }
  // Eliminar una comunidad de Firestore y del DataHolder
  Future<void> deleteCommunity(String communityId) async {
    try {
      await FirebaseFirestore.instance.collection('communities').doc(communityId).delete();
      print("Community deleted successfully");
      DataHolder().deleteCommunity(communityId);
    } catch (e) {
      print("Error deleting community: $e");
    }
  }


  /// Función genérica para obtener un documento específico desde Firestore.
  ///
  /// [collectionPath] es la ruta de la colección en Firestore (por ejemplo, "users").
  /// [docId] es el identificador único del documento dentro de la colección que se desea obtener.
  /// [onError] es un callback opcional que se ejecuta si ocurre un error durante la consulta.
  ///   - Recibe un mensaje de error como argumento.
  ///
  /// Retorna un [DocumentSnapshot<Map<String, dynamic>>?]:
  ///   - Si el documento existe, se devuelve el snapshot del documento.
  ///   - Si el documento no existe o ocurre un error, retorna `null`.
  Future<DocumentSnapshot<Map<String, dynamic>>?> fetchFBData({
    required String collectionPath,
    required String docId,
    Function(String)? onError,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final documentSnapshot = await firestore.collection(collectionPath).doc(docId).get();
      if (documentSnapshot.exists) {
        return documentSnapshot;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching data: $e');
      if(onError != null) onError('Error al guardar el perfil: $e');
    }
    return null;
  }

  /// Función genérica para obtener una lista de datos desde Firestore.
  /// [collectionPath] es la ruta de la colección.
  /// [filters] es opcional para obtener solo los datos que respeten unos filtros
  Future<List<DocumentSnapshot<Map<String, dynamic>>>?> fetchFBDataList({
    required String collectionPath,
    Map<String, dynamic>? filters,
  }) async {

    return null;
  }

  /// Función genérica para subir datos a Firestore.
  ///
  /// [collectionPath] es la ruta de la colección en Firestore (por ejemplo, "users").
  /// [data] es un mapa que contiene los datos que se desean guardar en Firestore.
  /// [docId] es el identificador único del documento dentro de la colección.
  ///   - Si se proporciona, se usará este ID para el documento.
  ///   - Si se omite, Firestore generará automáticamente un ID único para el documento.
  /// [onError] es un callback opcional que se ejecuta si ocurre un error durante la operación.
  ///   - Recibe un mensaje de error como argumento.
  ///
  /// Esta función guarda los datos en Firestore:
  ///   - Si [docId] se proporciona, usa el método `set` para sobrescribir o crear el documento con ese ID.
  ///   - Si [docId] no se proporciona, usa el método `add` para crear un documento con un ID generado automáticamente.
  ///
  /// No retorna ningún valor. Si ocurre un error, se ejecuta el callback [onError] si está definido.
    Future<void> saveFBData({
      required String collectionPath,
      required Map<String, dynamic> data,
      String? docId,
      Function(String)? onError
    }) async{
    try {
      if (docId != null) {
        await FirebaseFirestore.instance
            .collection(collectionPath)
            .doc(docId)
            .set(data);
      } else{
        await FirebaseFirestore.instance
            .collection(collectionPath)
            .add(data);
      }
    } catch (e) {
      if(onError != null) onError('Error al guardar el perfil: $e');
    }
  }


}