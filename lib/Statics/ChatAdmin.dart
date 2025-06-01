import 'package:cloud_firestore/cloud_firestore.dart';

import '../FBObjects/FbMensaje.dart';

class ChatAdmin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicia un chat entre dos usuarios.
  /// Retorna el `chatId` del chat creado o existente.
  Future<void> startChat(String userAId, String userBId, String mensajeInicial) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Generar ID único para el chat
    final List<String> userIds = [userAId, userBId]..sort();
    final String chatId = '${userIds[0]}_${userIds[1]}';

    final DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
    final DocumentSnapshot chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      // Crear el chat
      await chatRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'participants': userIds,
      });

      // Añadir la referencia del chat en cada usuario
      for (String uid in userIds) {
        final userChatRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('chats')
            .doc(chatId);

        await userChatRef.set({
          'chatId': chatId,
          'with': uid == userAId ? userBId : userAId,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Crear mensaje (tanto si el chat es nuevo como si ya existía)
    final mensaje = FbMensaje(
      texto: mensajeInicial,
      autorId: userAId,
      fecha: Timestamp.now(),
      visto: false,
      gustado: false,
    );

    await chatRef.collection('mensajes').add(mensaje.toFirestore());

    // También puedes actualizar info adicional si quieres como lastUpdated
    await chatRef.update({
      'lastMessage': mensajeInicial,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }



  Stream<List<FbMensaje>> getMensajesTiempoReal(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .orderBy('fecha', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FbMensaje.fromFirestore(doc);
      }).toList();
    });
  }


  /// Elimina un mensaje específico de un chat.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.delete();
  }

  Future<void> eliminarChat(String chatId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      // 1. Obtener los participantes
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) return;

      final data = chatDoc.data()!;
      final List<dynamic> participants = data['participants'];

      // 2. Borrar subcolección de mensajes
      final mensajesSnapshot = await chatRef.collection('mensajes').get();
      for (final doc in mensajesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3. Borrar el documento del chat
      await chatRef.delete();

      // 4. Borrar referencias en la colección de cada usuario
      for (String uid in participants) {
        final userChatRef =
        firestore.collection('users').doc(uid).collection('chats').doc(chatId);
        await userChatRef.delete();
      }

      print("✅ Chat eliminado correctamente.");
    } catch (e) {
      print("❌ Error al eliminar el chat: $e");
    }
  }
}