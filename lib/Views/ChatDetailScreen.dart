import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

  // Función para enviar un mensaje de texto
  void _sendMessage({String? fileUrl, String? fileType}) async {
    if (_messageController.text.trim().isEmpty && fileUrl == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': _messageController.text.trim(),
      'senderId': 'currentUser',
      'fileUrl': fileUrl, // URL del archivo si existe
      'fileType': fileType, // Tipo del archivo (image, video, audio)
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();
  }

  // Función para seleccionar un archivo desde el dispositivo
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Solo selecciona un archivo
      type: FileType.any, // Permite cualquier tipo de archivo
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // Subir archivo a Firebase Storage
      await _uploadFileToFirebase(file, fileName, result.files.single.extension);
    }
  }

  Future<void> _pickImageOrVideo(bool isImage) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (isImage) {
      // Seleccionar una imagen
      pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
    } else {
      // Seleccionar un video
      pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
      );
    }

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = pickedFile.name;

      await _uploadFileToFirebase(file, fileName, isImage ? 'image' : 'video');
    }
  }

  // Función para subir un archivo a Firebase Storage
  Future<void> _uploadFileToFirebase(File file, String fileName, String? fileType) async {
    String filePath = 'chats/${widget.chatId}/$fileName';
    Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;

    // Obtener la URL pública del archivo
    String downloadUrl = await snapshot.ref.getDownloadURL();

    // Enviar el mensaje con la URL del archivo
    _sendMessage(fileUrl: downloadUrl, fileType: fileType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay mensajes aún.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final text = message['text'];
                    final senderId = message['senderId'];
                    final fileUrl = message['fileUrl'];
                    final fileType = message['fileType'];

                    return ListTile(
                      title: Text(
                        senderId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: fileUrl != null
                          ? fileType == 'image'
                          ? Image.network(fileUrl, height: 150, fit: BoxFit.cover)
                          : fileType == 'video'
                          ? Text('📹 Video enviado')
                          : fileType == 'audio'
                          ? Text('🎵 Audio enviado')
                          : Text('📎 Archivo enviado')
                          : Text(text),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => _pickImageOrVideo(true),
                ),
                IconButton(
                  icon: const Icon(Icons.video_library),
                  onPressed: () => _pickImageOrVideo(false),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}