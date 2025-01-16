import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Para manejar archivos locales en dispositivos
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si estamos en Flutter Web
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Firestore
import '../FBObjects/FBPost.dart'; // Clase FBPost para manejar publicaciones
import '../FBObjects/FbPerfil.dart'; // Clase FbPerfil para representar el perfil del usuario

// Clase principal que define una vista para crear publicaciones
class CreatePostView extends StatefulWidget {
  final String autorID; // Identificador del usuario que crea la publicación

  CreatePostView({required this.autorID}); // Constructor para recibir el ID del autor

  @override
  _CreatePostViewState createState() => _CreatePostViewState();
}

// Clase que gestiona el estado de CreatePostView
class _CreatePostViewState extends State<CreatePostView> {
  // Controlador para el campo de texto donde el usuario escribe el contenido del post
  final TextEditingController _textController = TextEditingController();

  // Lista local para almacenar las publicaciones creadas por el usuario
  final List<FBPost> _posts = [];

  // Variable para almacenar la ruta de la imagen seleccionada antes de publicarla
  String? _selectedImagePath;

  // Perfil del usuario actual (se puede inicializar desde Firebase o usar valores predeterminados)
  late final FbPerfil _userProfile;

  @override
  void initState() {
    super.initState();
    // Inicialización del perfil del usuario con valores predeterminados
    // Estos valores deberían reemplazarse por datos reales si están disponibles
    _userProfile = FbPerfil(
      nombre: 'John Doe',
      apodo: 'johnd',
      imagenURL: 'https://example.com/profile.jpg',
      cumple: '1990-01-01',
    );
  }

  // Función para manejar el envío de una publicación
  // Toma el texto y la imagen (si existe) y guarda la publicación en Firebase
  void _sendPost(String texto, String? imagePath) async {
    final firestore = FirebaseFirestore.instance; // Instancia de Firestore

    // Crear un nuevo objeto FBPost con los datos del usuario y la publicación
    FBPost newPost = FBPost(
      texto: texto,
      imagenURL: imagePath,
      fechaCreacion: DateTime.now(),
      autorID: widget.autorID, // Se utiliza el ID del autor proporcionado al crear la vista
    );

    // Guardar la publicación en la colección "posts" de Firebase
    await firestore.collection('posts').add(newPost.toFirestore());

    // Actualizar la lista local de publicaciones para reflejar la nueva publicación
    setState(() {
      _posts.add(newPost);
      _selectedImagePath = null; // Limpiar la previsualización de imagen
    });
  }

  // Función para abrir un modal que permite al usuario crear una nueva publicación
  Future<void> _openPostModal() async {
    String message = ''; // Variable para almacenar el texto del mensaje
    _selectedImagePath = null; // Limpiar cualquier selección previa de imagen

    // Mostrar un cuadro de diálogo donde el usuario puede escribir y seleccionar una imagen
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Asegura que el modal no ocupe toda la pantalla
                  children: [
                    // Campo de texto para ingresar el contenido del post
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Escribe algo...', // Sugerencia para el usuario
                        border: OutlineInputBorder(), // Borde para el campo de texto
                      ),
                      onChanged: (value) {
                        message = value; // Actualizar el mensaje con lo que escribe el usuario
                      },
                    ),
                    const SizedBox(height: 10), // Espaciador vertical

                    // Muestra una previsualización de la imagen seleccionada (si existe)
                    if (_selectedImagePath != null)
                      kIsWeb
                          ? Image.network(
                        _selectedImagePath!, // Mostrar imagen desde URL en Flutter Web
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      )
                          : Image.file(
                        File(_selectedImagePath!), // Mostrar imagen desde archivo local
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 10),

                    // Botones para seleccionar una imagen y enviar el post
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Alineación uniforme
                      children: [
                        // Botón para abrir la galería y seleccionar una imagen
                        IconButton(
                          icon: Icon(Icons.photo), // Ícono de foto
                          onPressed: () async {
                            final picker = ImagePicker(); // Instancia de ImagePicker
                            final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery); // Selección desde galería
                            if (pickedFile != null) {
                              setState(() {
                                _selectedImagePath = pickedFile.path; // Guardar la ruta de la imagen
                              });
                            }
                          },
                        ),
                        // Botón para publicar el mensaje y cerrar el modal
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar el modal
                            _sendPost(message, _selectedImagePath); // Enviar el post
                            _textController.clear(); // Limpiar el campo de texto
                          },
                          child: Text('Publicar'), // Texto del botón
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Publicación'), // Título en la barra superior
      ),
      body: Column(
        children: [
          // Lista que muestra las publicaciones creadas
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length, // Número de publicaciones en la lista
              itemBuilder: (context, index) {
                final post = _posts[index]; // Obtener cada publicación
                return ListTile(
                  title: Text(post.texto), // Mostrar el texto de la publicación
                  subtitle: Text('Creado el: ${post.fechaCreacion}'), // Mostrar la fecha de creación
                  trailing: post.imagenURL != null
                      ? (kIsWeb
                      ? Image.network(post.imagenURL!, width: 50, height: 50) // Imagen en Web
                      : Image.file(File(post.imagenURL!), width: 50, height: 50)) // Imagen en local
                      : null,
                );
              },
            ),
          ),
          // Botón para abrir el modal y crear una nueva publicación
          Padding(
            padding: const EdgeInsets.all(16.0), // Espaciado alrededor del botón
            child: ElevatedButton(
              onPressed: _openPostModal, // Función que abre el modal
              child: Text('Crear Publicación'), // Texto del botón
            ),
          ),
        ],
      ),
    );
  }
}

