import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triboo/Statics/DataHolder.dart';
import 'package:triboo/FBObjects/FbPerfil.dart'; // Asegúrate que la ruta sea correcta
import '../FBObjects/FbCommunity.dart';
import '../FBObjects/FBPost.dart';
import '../Statics/FirebaseAdmin.dart';

class CreatePostView extends StatefulWidget {
  final FbCommunity community;

  CreatePostView({required this.community});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final TextEditingController _messageController = TextEditingController();

  void _publishMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    try {
      // 1. Obtener el documento del perfil del usuario
      final perfilDoc = await FirebaseFirestore.instance
          .collection('users') // Asegúrate que esta es tu colección correcta
          .doc(currentUser.uid)
          .get();

      if (!perfilDoc.exists) {
        throw Exception('Perfil de usuario no encontrado');
      }

      // 2. Obtener el apodo directamente del documento (sin convertir a FbPerfil)
      final apodo = perfilDoc.data()?['apodo'] ?? 'Anónimo';

      // 3. Crear el post con el apodo
      FBPost newPost = FBPost(
        texto: message,
        imagenURL: null,
        fechaCreacion: DateTime.now(),
        autorID: currentUser.uid,
        autorApodo: apodo, // Usamos el apodo obtenido
      );

      await DataHolder().fbAdmin.saveFBData(
        collectionPath: 'comunidades',
        docId: widget.community.id,
        subcollectionPath: 'posts',
        data: newPost.toFirestore(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje publicado')),
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Post en ${widget.community.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Escribe un mensaje...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _publishMessage,
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
