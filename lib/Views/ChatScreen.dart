import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../FBObjects/FbMensaje.dart';
import '../Statics/DataHolder.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Stream<List<FbMensaje>> mensajes;
  String? otherUserImage;


  @override
  void initState() {
    super.initState();
    mensajes = DataHolder().chatAdmin.getMensajesTiempoReal(widget.chatId);
    cargarImagenDelOtroUsuario();
  }

  Future<void> cargarImagenDelOtroUsuario() async {
    final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final List<dynamic> participantes = doc['participants'];
    final String otherUserId = participantes.firstWhere((id) => id != DataHolder.currentUserId);

    final otherDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
    setState(() {
      otherUserImage = otherDoc['imagenURL'] ?? '';
    });
  }

  Future<void> _enviarMensajeAIA(String chatId, String mensaje) async {
    final uri = Uri.parse('https://mensajeaia-e5mf2zshgq-uc.a.run.app'); // 🔁 Usa tu URL exacta

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'chatId': chatId,
        'mensaje': mensaje,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Mensaje procesado por IA correctamente');
    } else {
      print('❌ Error al procesar con IA: ${response.body}');
    }
  }



  Future<void> enviarMensaje() async {
    final String texto = _messageController.text.trim();
    if (texto.isEmpty) return;
    final isChatWithIA = widget.chatId.contains(DataHolder().BRAINITO_ID);

    if (isChatWithIA) {
      await _enviarMensajeAIA(widget.chatId, texto);
    }
    final Timestamp ahora = Timestamp.now();

    final mensaje = FbMensaje(
      texto: texto,
      autorId: DataHolder.currentUserId,
      fecha: ahora,
      visto: false,
      gustado: false,
    );

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final mensajesRef = chatRef.collection('mensajes');

    await mensajesRef.add(mensaje.toFirestore());

    await chatRef.update({
      'lastUpdated': ahora,
      'lastMessage': texto,
    });

    _messageController.clear();
  }

  String _formatHora(Timestamp fecha) {
    final dt = fecha.toDate();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<FbMensaje>>(
              stream: mensajes,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensajesList = snapshot.data!;

                return ListView.builder(
                  itemCount: mensajesList.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajesList[index];
                    final bool isMine = mensaje.autorId == DataHolder.currentUserId;

                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment:
                        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMine)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 6),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundImage: (otherUserImage != null && otherUserImage!.isNotEmpty)
                                    ? NetworkImage(otherUserImage!)
                                    : null,
                                child: (otherUserImage == null || otherUserImage!.isEmpty)
                                    ? const Icon(Icons.person, size: 16)
                                    : null,
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? colorScheme.primary // fondo verde oscuro para tus mensajes
                                  : Color(0xFF144D53),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMine ? const Radius.circular(12) : Radius.zero,
                                bottomRight: isMine ? Radius.zero : const Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mensaje.texto,
                                  style: TextStyle(
                                    color: isMine ? Colors.white : Color(0xFFB2DFDB),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatHora(mensaje.fecha),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine ? colorScheme.onSurface.withOpacity(0.8) : Colors.white38,
                                  ),
                                ),
                              ],
                            ),

                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _messageController,
                            label: 'Escribe un mensaje...',
                            icon: Icons.message,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: colorScheme.primary),
                          onPressed: enviarMensaje,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildTextField(
    BuildContext context, {
      required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isPassword = false,
      bool obscure = false,
      bool visible = false,
      VoidCallback? toggleVisibility,
    }) {
  final colorScheme = Theme.of(context).colorScheme;

  return TextFormField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        margin: const EdgeInsets.all(6),
        child: Icon(icon, color: colorScheme.primary),
      ),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(
          visible ? Icons.visibility : Icons.visibility_off,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        onPressed: toggleVisibility,
      )
          : null,
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
    ),
    style: TextStyle(color: colorScheme.onSurface),
  );
}

