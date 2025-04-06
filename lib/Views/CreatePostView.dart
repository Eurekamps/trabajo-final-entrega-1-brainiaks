import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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

  // MÉTODO ORIGINAL SIN MODIFICACIONES (solo se añadió tags al post)
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
      final perfilDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!perfilDoc.exists) throw Exception('Perfil no encontrado');

      final apodo = perfilDoc.data()?['apodo'] ?? 'Anónimo';

      FBPost newPost = FBPost(
        texto: message,
        imagenURL: null,
        fechaCreacion: DateTime.now(),
        autorID: currentUser.uid,
        autorApodo: apodo,
        tags: _selectedTags, // Nuevo campo añadido
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
      _selectedTags.clear();
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
        title: Text(
          'Crear Post',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        elevation: 0,
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
            // Área de texto
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de texto
                    TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: '¿Qué quieres compartir?',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),

                    // Selector de tags
                    const SizedBox(height: 16),
                    const Text(
                      'Etiquetas:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return ChoiceChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (_) => _toggleTag(tag),
                          selectedColor: Colors.blue.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Selector de emojis
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    if (emoji != null) {
                      setState(() {
                        _messageController.text += emoji.emoji;
                      });
                    }
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

            // Barra de herramientas
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions),
                    color: Colors.grey,
                    onPressed: _toggleEmojiPicker,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _publishMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
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