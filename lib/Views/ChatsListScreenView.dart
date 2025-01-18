import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ChatDetailScreen.dart';

// Pantalla principal que muestra la lista de chats
class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String searchQuery = ""; // Variable para almacenar el texto ingresado en el campo de búsqueda

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar con campo de búsqueda al estilo WhatsApp
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() {
              // Actualizamos el texto de búsqueda y convertimos a minúsculas
              searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Buscar chats...", // Texto de sugerencia en el campo de búsqueda
            border: InputBorder.none, // Sin borde
            prefixIcon: Icon(Icons.search, color: Colors.white), // Icono de búsqueda
            hintStyle: TextStyle(color: Colors.white54), // Estilo del texto de sugerencia
          ),
          style: TextStyle(color: Colors.white), // Estilo del texto ingresado
        ),
        backgroundColor: Color(0xFF075E54), // Color del AppBar (verde estilo WhatsApp)
      ),
      // Cuerpo principal de la pantalla que muestra la lista de chats
      body: StreamBuilder(
        // Se conecta a la colección 'chats' de Firebase Firestore
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Muestra un indicador de carga mientras los datos están siendo recuperados
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Filtramos los chats según el texto ingresado en el campo de búsqueda
          final filteredChats = snapshot.data!.docs.where((chat) {
            final chatName = chat['name'].toString().toLowerCase(); // Nombre del chat en minúsculas
            return chatName.contains(searchQuery); // Filtra si contiene el texto buscado
          }).toList();

          // ListView que muestra la lista de chats
          return ListView.builder(
            itemCount: filteredChats.length, // Número total de chats filtrados
            itemBuilder: (context, index) {
              final chat = filteredChats[index]; // Chat actual en la iteración

              return ListTile(
                title: Text(chat['name']), // Muestra el nombre del chat
                subtitle: Text(
                  chat['lastMessage'] ?? "No hay mensajes aún", // Muestra el último mensaje o un texto predeterminado
                ),
                trailing: Text(
                  // Formateamos la hora del último mensaje si existe
                  chat['lastMessageTime'] != null
                      ? _formatTimestamp(chat['lastMessageTime'])
                      : '',
                ),
                onTap: () {
                  // Navega a la pantalla de detalles del chat al hacer clic
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(chatId: chat.id),
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

  // Método para formatear la fecha/hora del último mensaje usando Timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate(); // Convertimos el Timestamp en un objeto DateTime
    // Devolvemos el formato HH:MM
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
