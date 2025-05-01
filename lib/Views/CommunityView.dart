import 'dart:io';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../FBObjects/FbCommunity.dart';
import '../Statics/DataHolder.dart';
import '../Statics/FirebaseAdmin.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CommunityView extends StatefulWidget {
  @override
  _CommunityViewState createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  final FirebaseAdmin _firebaseAdmin = DataHolder().fbAdmin;
  String currentUserId = "";
  bool _isLoading = true;

  // Nuevas variables para búsqueda y categoría seleccionada
  String selectedCategory = ''; // Almacena la categoría seleccionada
  String searchName = ''; // Almacena el nombre a buscar

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    } else {
      print('No hay usuario autenticado');
    }
  }

  // MÉTODO MODIFICADO: Eliminado el currentUserId de uidParticipants al crear
  Future<void> _createCommunity(String name, String description,
      String category, XFile? imageFile) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('comunidades').doc();
      final newId = docRef.id;

      String avatarUrl = '';
      if (imageFile != null) {
        avatarUrl = await uploadCommunityAvatar(newId, imageFile) ?? '';
      }

      final newCommunity = FbCommunity(
        id: newId,
        uidCreator: currentUserId,
        uidModders: '',
        uidParticipants: [],
        name: name,
        description: description,
        avatar: avatarUrl,
        category: category,
      );

      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: newCommunity.toFirestore(),
        docId: newId,
      );

      DataHolder().addCommunity(newCommunity);
      setState(() {});
    } catch (e) {
      print('Error al crear la comunidad: $e');
    }
  }

  Future<String?> uploadCommunityAvatar(String communityId, XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref('imagenes/comunidades/$communityId/avatar.jpg');

      String downloadUrl;

      if (kIsWeb) {
        final Uint8List imageBytes = await image.readAsBytes();
        final mimeType = lookupMimeType(image.name);

        final metadata = SettableMetadata(
          contentType: mimeType ?? 'application/octet-stream',
          cacheControl: 'public, max-age=31536000',
        );

        final uploadTask = storageRef.putData(imageBytes, metadata);
        await uploadTask.whenComplete(() =>
            print("✅ Avatar de comunidad subido (web)"));

        downloadUrl = await storageRef.getDownloadURL();
      } else {
        final file = File(image.path);
        final uploadTask = storageRef.putFile(file);
        await uploadTask.whenComplete(() =>
            print("✅ Avatar de comunidad subido (móvil)"));

        downloadUrl = await storageRef.getDownloadURL();
      }

      print('📥 URL avatar comunidad: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print("❌ Error subiendo avatar de comunidad: $e");
      return null;
    }
  }


  // Resto de los métodos permanecen exactamente igual...
  Future<void> _updateCommunity(String id, String newName,
      String newDescription, String newCategory) async {
    try {
      // Buscar la comunidad que vamos a actualizar
      final communityToUpdate = DataHolder().allCommunities.firstWhere((
          community) => community.id == id);

      // Crear el objeto de la comunidad con los nuevos valores
      final updatedCommunity = FbCommunity(
        id: communityToUpdate.id,
        uidCreator: communityToUpdate.uidCreator,
        uidModders: communityToUpdate.uidModders,
        uidParticipants: communityToUpdate.uidParticipants,
        name: newName,
        description: newDescription,
        avatar: communityToUpdate.avatar,
        category: newCategory, // Añadir el campo de categoría actualizado
      );

      // Guardar los cambios en Firestore
      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: updatedCommunity.toFirestore(),
        docId: updatedCommunity.id,
      );

      // Actualizar la comunidad en el DataHolder (para reflejar los cambios en la UI)
      DataHolder().updateCommunity(updatedCommunity);
      setState(() {}); // Refrescar la UI
    } catch (e) {
      print('Error al actualizar la comunidad: $e');
    }
  }


  Future<void> _deleteCommunity(String id) async {
    try {
      await _firebaseAdmin.deleteFBData(
        collectionPath: 'comunidades',
        docId: id,
      );
      DataHolder().removeCommunity(id);
      setState(() {});
    } catch (e) {
      print('Error al eliminar la comunidad: $e');
    }
  }

  void _showEditCommunityDialog(FbCommunity community) {
    final nameController = TextEditingController(text: community.name);
    final descriptionController = TextEditingController(
        text: community.description);

    // Inicializar el valor de la categoría seleccionada
    String selectedCategory = community
        .category; // Suponiendo que 'category' está en FbCommunity

    // Lista de categorías disponibles para seleccionar
    List<String> categories = [
      'Deportes',
      'Ocio',
      'Negocios',
      'Libros'
    ]; // Puedes personalizar esta lista

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Comunidad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nuevo nombre'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Nueva descripción'),
              ),
              // Agregar el DropdownButton para la categoría
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (String? newCategory) {
                  if (newCategory != null) {
                    setState(() {
                      selectedCategory = newCategory;
                    });
                  }
                },
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newDescription = descriptionController.text.trim();
                if (newName.isNotEmpty && newDescription.isNotEmpty) {
                  // Pasar también la categoría seleccionada al método de actualización
                  _updateCommunity(
                      community.id, newName, newDescription, selectedCategory);
                  Navigator.pop(context);
                }
              },
              child: Text('Guardar cambios'),
            ),
          ],
        );
      },
    );
  }


  Widget _buildCommunitySection({
    required String title,
    required List<FbCommunity> communities,
    required bool showEditAndDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          communities.isEmpty
              ? Text('No hay comunidades en esta sección.')
              : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: ClipOval(
                    child: community.avatar.isNotEmpty
                        ? Image.network(
                      community.avatar,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: Icon(Icons.group, size: 30, color: Colors.grey[700]),
                    ),
                  ),
                  title: Text(community.name),
                  subtitle: Text(community.description),
                  trailing: showEditAndDelete
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditCommunityDialog(community),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCommunity(community.id),
                      ),
                    ],
                  )
                      : title == "Comunidades a las que pertenezco"
                      ? _buildLeaveButton(community)
                      : _buildJoinButton(community),
                ),

              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(FbCommunity community) {
    final isUserParticipant = community.uidParticipants.contains(currentUserId);

    if (isUserParticipant) {
      return SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: () => _joinCommunity(community),
      child: Text('Unirse'),
    );
  }

  Widget _buildLeaveButton(FbCommunity community) {
    return ElevatedButton(
      onPressed: () => _leaveCommunity(community),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      child: Text('Abandonar', style: TextStyle(color: Colors.white)),
    );
  }

  Future<void> _leaveCommunity(FbCommunity community) async {
    try {
      community.uidParticipants.remove(
          currentUserId); // Remover usuario de la lista

      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: community.toFirestore(),
        docId: community.id,
      );

      // Actualizar en DataHolder
      DataHolder().joinedCommunities.removeWhere((c) => c.id == community.id);

      setState(() {}); // Refrescar la UI
    } catch (e) {
      print('Error al abandonar la comunidad: $e');
    }
  }

  Future<void> _joinCommunity(FbCommunity community) async {
    try {
      community.uidParticipants.add(currentUserId);
      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: community.toFirestore(),
        docId: community.id,
      );
      DataHolder().addCommunity(community);
      setState(() {});
    } catch (e) {
      print('Error al unirse a la comunidad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comunidades'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommunitySection(
              title: 'Mis Comunidades',
              communities: DataHolder().createdCommunities,
              showEditAndDelete: true,
            ),
            _buildCommunitySection(
              title: 'Comunidades a las que pertenezco',
              communities: DataHolder().joinedCommunities,
              showEditAndDelete: false,
            ),
            // StreamBuilder para comunidades existentes
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('comunidades').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final allCommunities = snapshot.data!.docs.map((doc) =>
                    FbCommunity.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)
                ).toList();

                final filteredCommunities = allCommunities.where((community) =>
                !community.uidParticipants.contains(currentUserId) &&
                    community.uidCreator != currentUserId &&
                    (selectedCategory.isEmpty || selectedCategory == 'Todas' || community.category == selectedCategory) &&
                    (searchName.isEmpty || community.name.toLowerCase().contains(searchName.toLowerCase()))
                ).toList();

                final displayedCommunities = (selectedCategory.isEmpty || selectedCategory == 'Todas') && searchName.isEmpty
                    ? filteredCommunities.take(5).toList()
                    : filteredCommunities;

                Icon _getCategoryIcon(String category) {
                  switch (category) {
                    case 'Deportes':
                      return Icon(Icons.sports_soccer, color: Colors.green);
                    case 'Ocio':
                      return Icon(Icons.movie, color: Colors.purple);
                    case 'Negocios':
                      return Icon(Icons.business_center, color: Colors.orange);
                    case 'Libros':
                      return Icon(Icons.menu_book, color: Colors.brown);
                    default:
                      return Icon(Icons.category, color: Colors.grey);
                  }
                }

                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(selectedCategory + searchName),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Buscar comunidades",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Escribe el nombre...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchName = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Filtrar por categoría:",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                                ),
                              ),
                              value: selectedCategory.isEmpty ? 'Todas' : selectedCategory,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategory = (newValue == 'Todas') ? '' : newValue ?? '';
                                });
                              },
                              selectedItemBuilder: (context) {
                                return ['Todas', 'Deportes', 'Ocio', 'Negocios', 'Libros'].map((category) {
                                  return Row(
                                    children: [
                                      _getCategoryIcon(category),
                                      const SizedBox(width: 8),
                                      Text(category),
                                    ],
                                  );
                                }).toList();
                              },
                              items: ['Todas', 'Deportes', 'Ocio', 'Negocios', 'Libros'].map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Row(
                                    children: [
                                      _getCategoryIcon(category),
                                      const SizedBox(width: 8),
                                      Text(category),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      _buildCommunitySection(
                        title: 'Comunidades Existentes',
                        communities: displayedCommunities,
                        showEditAndDelete: false,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCommunityDialog,
        child: Icon(Icons.add),
        tooltip: 'Crear nueva comunidad',
      ),
    );
  }


  void _showCreateCommunityDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Deportes';
    List<String> categories = ['Deportes', 'Ocio', 'Negocios', 'Libros'];

    XFile? selectedImage;
    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Crear Comunidad'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final ImageSource? pickedSource = await showDialog<ImageSource>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Seleccionar Imagen"),
                              content: Text("¿Quieres tomar una foto o seleccionar de la galería?"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                                  child: Text("Tomar Foto"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                                  child: Text("Seleccionar de la Galería"),
                                ),
                              ],
                            );
                          },
                        );

                        if (pickedSource != null) {
                          final XFile? file = await ImagePicker().pickImage(source: pickedSource);
                          if (file != null) {
                            final bytes = await file.readAsBytes();
                            setState(() {
                              selectedImage = file;
                              imageBytes = bytes;
                            });
                          }
                        }
                      },
                      child: ClipOval(
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: imageBytes != null
                              ? Image.memory(imageBytes!, fit: BoxFit.cover)
                              : Icon(Icons.camera_alt, size: 40, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Nombre de la comunidad'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Descripción de la comunidad'),
                    ),
                    DropdownButton<String>(
                      value: selectedCategory,
                      onChanged: (String? newCategory) {
                        if (newCategory != null) {
                          setState(() {
                            selectedCategory = newCategory;
                          });
                        }
                      },
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty && description.isNotEmpty) {
                  _createCommunity(name, description, selectedCategory, selectedImage);
                  Navigator.pop(context);
                }
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }

}
