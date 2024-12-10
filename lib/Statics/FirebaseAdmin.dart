import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:triboo/FBObjects/FbPerfil.dart';

import 'DataHolder.dart';

class FirebaseAdmin{

  late String logInError;

  /// Función para iniciar sesión en Firebase con correo electrónico y contraseña.
  ///
  /// [email] es el correo electrónico del usuario que intenta iniciar sesión.
  /// [password] es la contraseña del usuario para la autenticación.
  /// [onError] es un callback opcional que se ejecuta si ocurre un error durante la operación.
  ///   - Recibe un mensaje de error como argumento.
  ///
  /// Esta función intenta autenticar al usuario con el correo electrónico y la contraseña proporcionados.
  ///   - Si la autenticación es exitosa, obtiene el perfil del usuario desde Firestore y lo almacena en la clase `DataHolder`.
  ///   - Si el perfil no se encuentra en Firestore o ocurre algún error, establece el perfil como `null` y ejecuta el callback [onError], si está definido.
  ///
  /// La función no retorna ningún valor. En caso de error, se ejecuta el callback [onError], si está definido.
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// await logIn("usuario@ejemplo.com", "contraseña123", (error) {
  ///   print("Error: $error");
  /// });
  /// ```
  Future<void> logIn({
    required String email,
    required String password,
    Function(String)? onError,
  }) async {
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
        if(onError != null) onError('Error al Iniciar Sesión: $e');

      }
    } on FirebaseAuthException catch (e) {
     logInError = e.message!;
     if(onError != null) onError('Error al Iniciar Sesión: $e');
    }
    return ;
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
  ///
  /// [collectionPath] es la ruta de la colección en Firestore (por ejemplo, "users").
  /// [filters] es un parámetro opcional que permite aplicar un filtro a la consulta.
  ///   - Si se proporciona, se usa para filtrar los documentos de la colección.
  ///   - Si es nulo, no se aplican filtros y se obtienen todos los documentos de la colección.
  /// [onError] es un callback opcional que se ejecuta si ocurre un error durante la operación.
  ///   - Recibe un mensaje de error como argumento.
  ///
  /// Esta función obtiene una lista de documentos desde la colección especificada en Firestore:
  ///   - Si [filters] se proporciona, se utiliza el filtro para obtener solo los documentos que coincidan.
  ///   - Si [filters] es nulo, se obtienen todos los documentos de la colección.
  ///
  /// El resultado es una lista de documentos (`List<DocumentSnapshot<Map<String, dynamic>>>`),
  /// que contiene los datos de cada documento de la colección.
  ///
  /// Si ocurre un error, se ejecuta el callback [onError] si está definido.
  ///
  /// Ejemplo de uso:
  ///
  ///
  ///     for(var post in fetchedPosts!){
  ///
  ///       setState(() {
  ///
  ///         posts.add(FbPost.fromFirestore(post,null));
  ///
  ///       });
  ///
  ///     }
  /// ```
  Future<List<DocumentSnapshot<Map<String, dynamic>>>?>fetchFBDataList({
    required String collectionPath,
    //required Object transformFBObject,
    Filter? filters,
    Function(String)? onError,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      var query;
      if(filters == null){
        query = firestore.collection(collectionPath);
      }else{
        query = firestore.collection(collectionPath).where(filters);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching paginated collection: $e');
      if (onError != null) onError('Error al obtener la colección paginada: $e');
    }
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

  /// Función genérica para eliminar un documento en Firestore.
  ///
  /// [collectionPath] es la ruta de la colección en Firestore (por ejemplo, "users").
  /// [docId] es el identificador único del documento que se desea eliminar.
  /// [onError] es un callback opcional que se ejecuta si ocurre un error durante la operación.
  ///   - Recibe un mensaje de error como argumento.
  ///
  /// Esta función elimina el documento con el ID especificado de la colección de Firestore:
  ///   - Si el documento existe, se elimina de la colección.
  ///   - Si ocurre un error, se ejecuta el callback [onError] si está definido.
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// await deleteFBData(
  ///   collectionPath: "users",
  ///   docId: "user123",
  ///   onError: (error) => print(error),
  /// );
  /// ```
  Future<DocumentSnapshot<Map<String, dynamic>>?> deleteFBData({
    required String collectionPath,
    required String docId,
    Function(String)? onError,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      print('Error fetching data: $e');
      if(onError != null) onError('Error al guardar el perfil: $e');
    }
    return null;
  }
}