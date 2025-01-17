import 'package:flutter/material.dart'; // Biblioteca para construir interfaces en Flutter
import 'package:image_picker/image_picker.dart'; // Biblioteca para seleccionar imágenes desde la galería o cámara
import 'dart:io'; // Para trabajar con archivos locales (en dispositivos no web)
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si estamos ejecutando en Flutter Web
import 'package:cloud_firestore/cloud_firestore.dart'; // Biblioteca para conectar con Firebase Firestore (base de datos)
import '../FBObjects/FBPost.dart'; // Clase personalizada para manejar publicaciones (FBPost)
import '../FBObjects/FbPerfil.dart'; // Clase personalizada para manejar perfiles de usuario (FbPerfil)

// Clase principal que define la pantalla donde el usuario puede crear publicaciones
class CreatePostView extends StatefulWidget {
  final String autorID; // Identificador del autor de las publicaciones (se pasa al crear la vista)

  CreatePostView({required this.autorID}); // Constructor que recibe el ID del autor

  @override
  _CreatePostViewState createState() => _CreatePostViewState(); // Crea el estado asociado a esta pantalla
}

// Clase que maneja el estado y el comportamiento de CreatePostView
class _CreatePostViewState extends State<CreatePostView> {
  // Controlador para el campo de texto donde el usuario escribe el contenido de la publicación
  final TextEditingController _textController = TextEditingController();

  // Lista local para almacenar las publicaciones (no conecta directamente con Firebase)
  final List<FBPost> _posts = [];

  // Ruta de la imagen seleccionada por el usuario (si existe)
  String? _selectedImagePath;

  // Perfil del usuario que está creando publicaciones
  late final FbPerfil _userProfile;

  @override
  void initState() {
    super.initState();
    // Inicialización del perfil del usuario con valores predeterminados
    _userProfile = FbPerfil(
      nombre: 'John Doe', // Nombre ficticio del usuario
      apodo: 'johnd', // Apodo ficticio
      imagenURL: 'https://example.com/profile.jpg', // URL ficticia para la imagen del perfil
      cumple: '1990-01-01', // Fecha de cumpleaños ficticia
    );
  }

  // Función que envía una publicación a Firebase
  void _sendPost(String texto, String? imagePath) async {
    final firestore = FirebaseFirestore.instance; // Conexión a Firebase Firestore

    // Crear un objeto FBPost con el texto, la imagen y la fecha de creación
    FBPost newPost = FBPost(
      texto: texto,
      imagenURL: imagePath, // URL o ruta de la imagen (puede ser nula)
      fechaCreacion: DateTime.now(), // Fecha actual
      autorID: widget.autorID, // ID del autor (pasado al crear esta vista)
    );

    // Guardar la publicación en la colección "posts" de Firebase
    await firestore.collection('posts').add(newPost.toFirestore());

    // Actualizar el estado para incluir la nueva publicación en la lista local
    setState(() {
      _posts.add(newPost);
      _selectedImagePath = null; // Limpiar la selección de imagen
    });
  }

  // Función que muestra un modal para crear una nueva publicación
  Future<void> _openPostModal() async {
    String message = ''; // Almacena el texto escrito por el usuario
    _selectedImagePath = null; // Limpia cualquier selección previa de imagen

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Evita que el modal ocupe toda la pantalla
                  children: [
                    // Campo de texto donde el usuario escribe el contenido de la publicación
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Escribe algo...', // Texto de sugerencia
                        border: OutlineInputBorder(), // Estilo del borde
                      ),
                      onChanged: (value) {
                        message = value; // Actualiza el mensaje mientras el usuario escribe
                      },
                    ),
                    const SizedBox(height: 10), // Espacio entre elementos

                    // Muestra una previsualización de la imagen seleccionada (si existe)
                    if (_selectedImagePath != null)
                      kIsWeb
                          ? Image.network(
                        _selectedImagePath!, // Mostrar imagen desde URL en Flutter Web
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover, // Ajustar imagen al espacio
                      )
                          : Image.file(
                        File(_selectedImagePath!), // Mostrar imagen local en dispositivos
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 10),

                    // Fila con botones para seleccionar una imagen y publicar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón para seleccionar una imagen desde la galería
                        IconButton(
                          icon: Icon(Icons.photo), // Icono de una foto
                          onPressed: () async {
                            final picker = ImagePicker(); // Inicializa el selector de imágenes
                            final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery); // Abre la galería
                            if (pickedFile != null) {
                              setState(() {
                                _selectedImagePath = pickedFile.path; // Guarda la ruta de la imagen
                              });
                            }
                          },
                        ),
                        // Botón para publicar el contenido y cerrar el modal
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Cierra el modal
                            _sendPost(message, _selectedImagePath); // Envía la publicación
                            _textController.clear(); // Limpia el campo de texto
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
        title: Text('Post Some'), // Título en la barra superior
      ),
      body: Column(
        children: [
          // Lista que muestra todas las publicaciones creadas
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length, // Cantidad de publicaciones
              itemBuilder: (context, index) {
                final post = _posts[index]; // Obtiene cada publicación
                return Padding(
                  padding: const EdgeInsets.all(8.0), // Margen alrededor del post
                  child: Card(
                    elevation: 4, // Efecto de sombra
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Alinear a la izquierda
                        children: [
                          // Mostrar la imagen si existe
                          if (post.imagenURL != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8), // Bordes redondeados
                              child: kIsWeb
                                  ? Image.network(
                                post.imagenURL!, // Imagen desde URL (Web)
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                                  : Image.file(
                                File(post.imagenURL!), // Imagen local (dispositivos)
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            post.texto, // Texto de la publicación
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Creado el: ${post.fechaCreacion}', // Fecha de creación
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Botón para abrir el modal y crear una publicación
          Padding(
            padding: const EdgeInsets.all(100.0),
            child: ElevatedButton(
              onPressed: _openPostModal, // Abre el modal
              child: Text('Postear'),
            ),
          ),
        ],
      ),
    );
  }
}
