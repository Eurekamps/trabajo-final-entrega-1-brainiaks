import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Statics/DataHolder.dart';
import 'ChatScreen.dart';



class ChatListScreenView extends StatefulWidget {
  const ChatListScreenView({Key? key}) : super(key: key);

  @override
  State<ChatListScreenView> createState() => _ChatListScreenViewState();
}

class _ChatListScreenViewState extends State<ChatListScreenView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _getUserChatsStream() {
    return _firestore
        .collection('users')
        .doc(DataHolder.currentUserId)
        .collection('chats')
        .orderBy('joinedAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DataHolder().userProfile!.apodo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getUserChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = snapshot.data?.docs ?? [];

          if (chatDocs.isEmpty) {
            return const Center(child: Text("No tienes chats activos."));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data();
              final String otherUserId = chatData['with'];
              final String chatId = chatData['chatId'];

              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text("Cargando..."),
                    );
                  }

                  final userData = userSnapshot.data!;
                  final String nombre = userData['nombre'] ?? 'Usuario';
                  final String imagenURL = userData['imagenURL'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundImage: imagenURL.isNotEmpty ? NetworkImage(imagenURL) : null,
                        child: imagenURL.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '@${userData['apodo'] ?? 'usuario'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar chat',
                        onPressed: () async {
                          await DataHolder().chatAdmin.eliminarChat(chatId);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chatId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
