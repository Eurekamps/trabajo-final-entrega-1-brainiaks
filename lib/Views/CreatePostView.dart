import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triboo/FBObjects/FbCommunity.dart';
import 'package:triboo/FBObjects/FBPost.dart';
import 'package:triboo/Statics/DataHolder.dart';

class CreatePostView extends StatefulWidget {
  final FbCommunity community;
  final VoidCallback? onPostCreated;

  const CreatePostView({
    required this.community,
    this.onPostCreated,
    Key? key,
  }) : super(key: key);

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final TextEditingController _messageController = TextEditingController();
  bool _showEmojiPicker = false;
  List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Actualidad',
    'Eventos',
    'Consejos',
    'Preguntas',
    'Celebraciones'
  ];

  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) FocusScope.of(context).unfocus();
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _selectImage() async {
    try {
      final ImageSource? pickedSource = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Seleccionar Imagen"),
            content: const Text(
                "¿Quieres tomar una foto o seleccionar de la galería?"),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                child: const Text("Tomar Foto"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                child: const Text("Seleccionar de la Galería"),
              ),
            ],
          );
        },
      );

      if (pickedSource != null) {
        final pickedFile = await _picker.pickImage(source: pickedSource);
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageFile = pickedFile;
            _imageBytes = bytes;
          });
          print('✅ Imagen cargada desde ${pickedSource == ImageSource.camera
              ? 'la cámara'
              : 'la galería'}');
        } else {
          print('⚠️ No se pudo obtener la imagen seleccionada');
        }
      } else {
        print('⚠️ No se seleccionó ninguna opción');
      }
    } catch (e) {
      print('❌ Error al seleccionar la imagen: $e');
    }
  }


  Future<String?> _uploadImageToStorage(XFile imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("⚠️ Usuario no autenticado");

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('imagenes/posts/${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg');

      String downloadUrl;

      if (kIsWeb) {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final mimeType = lookupMimeType(imageFile.name);

        final metadata = SettableMetadata(
          contentType: mimeType ?? 'application/octet-stream',
          cacheControl: 'public, max-age=31536000',
        );

        final uploadTask = storageRef.putData(imageBytes, metadata);
        await uploadTask.whenComplete(() => print("✅ Imagen subida en web"));

        downloadUrl = await storageRef.getDownloadURL();
      } else {
        final file = File(imageFile.path);
        final uploadTask = storageRef.putFile(file);
        await uploadTask.whenComplete(() => print("✅ Imagen subida en móvil"));

        downloadUrl = await storageRef.getDownloadURL();
      }

      return downloadUrl;
    } catch (e) {
      print("❌ Error al subir imagen: $e");
      return null;
    }
  }

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
      // Obtener los datos del perfil del usuario
      final perfilDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!perfilDoc.exists) throw Exception('Perfil no encontrado');

      final apodo = perfilDoc.data()?['apodo'] ?? 'Anónimo';
      final imagenPerfil = perfilDoc.data()?['imagenURL'] ?? ''; // Obtener imagen perfil

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImageToStorage(_imageFile!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir la imagen')),
          );
          return;
        }
      }

      // Crear el nuevo post con los datos, ahora con likes y reportes
      FBPost newPost = FBPost(
        id: '',
        autorID: currentUser.uid,
        autorApodo: apodo,
        autorImagenURL: imagenPerfil,
        texto: message,
        tags: _selectedTags,
        imagenURL: imageUrl,
        fechaCreacion: DateTime.now(),
        likes: 0, // Inicializamos con 0 likes
        reportes: 0, // Inicializamos con 0 reportes
      );

      // Guardar el post en Firestore dentro de la comunidad correspondiente
      await DataHolder().fbAdmin.saveFBData(
        collectionPath: 'comunidades',
        docId: widget.community.id,
        subcollectionPath: 'posts',
        data: newPost.toFirestore(),
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje publicado')),
      );
      _messageController.clear();
      _selectedTags.clear();
      setState(() {
        _imageFile = null;
        _imageBytes = null;
      });
      widget.onPostCreated?.call();
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
        title: const Text(
          'Crear Post',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: const InputDecoration.collapsed(
                          hintText: '¿Qué quieres compartir?',
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    if (_imageBytes != null) ...[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.memory(
                          _imageBytes!,
                          width: double.infinity,
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.35,
                          fit: BoxFit.cover,
                        )
                            : Image.file(
                          File(_imageFile!.path),
                          width: double.infinity,
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.35,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _selectImage,
                      child: Row(
                        children: [
                          const Icon(Icons.add_a_photo, color: Colors
                              .blueAccent),
                          const SizedBox(width: 8),
                          Text(
                            _imageFile == null
                                ? 'Añadir imagen'
                                : 'Cambiar imagen',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Etiquetas:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return ChoiceChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (_) => _toggleTag(tag),
                          selectedColor: Colors.blue.shade100,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.blue.shade800 : Colors
                                .black54,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      _messageController.text += emoji.emoji;
                    });
                  },
                  config: const Config(
                    emojiViewConfig: EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 32,
                      backgroundColor: Color(0xFFF2F2F2),
                    ),
                  ),
                ),
              ),

            // Botón inferior fijo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    color: Colors.grey,
                    onPressed: _toggleEmojiPicker,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _publishMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'Publicar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}