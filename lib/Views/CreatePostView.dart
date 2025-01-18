import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    // Obtener el UID del usuario autenticado
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    // Crea una instancia de FBPost con el UID del usuario
    FBPost newPost = FBPost(
      texto: message,
      imagenURL: null, // Aun no hacemos subida de imágenes asique lo dejo null
      fechaCreacion: DateTime.now(),
      autorID: currentUser.uid, // Usamos el UID del usuario actual
    );

    try {
      await FirebaseAdmin().saveFBData(
        collectionPath: 'comunidades/${widget.community.id}/posts',
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
