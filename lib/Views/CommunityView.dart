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

import '../Theme/AppColors.dart';

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground, // texto principal adaptado
            ),
          ),
          const SizedBox(height: 12),
          communities.isEmpty
              ? Text(
            'No hay comunidades en esta sección.',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: theme.colorScheme.surfaceVariant, // fondo de tarjeta adaptado
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar con borde adaptado
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary, // borde con color primario del tema
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            child: Icon(
                              Icons.group,
                              size: 30,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Contenido
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              community.description.isNotEmpty
                                  ? community.description
                                  : 'Sin descripción.',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (showEditAndDelete) ...[
                                  TextButton.icon(
                                    onPressed: () => _showEditCommunityDialog(community),
                                    icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                                    label: Text(
                                      'Editar',
                                      style: TextStyle(color: theme.colorScheme.primary),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _deleteCommunity(community.id),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.error,
                                    ),
                                    label: Text(
                                      'Eliminar',
                                      style: TextStyle(color: theme.colorScheme.error),
                                    ),
                                  ),
                                ] else if (title == "Comunidades a las que pertenezco") ...[
                                  _buildLeaveButton(community),
                                ] else ...[
                                  _buildJoinButton(community),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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


    return ElevatedButton.icon(
      onPressed: () => _joinCommunity(community),
      icon: Icon(Icons.group_add),
      label: Text('Unirse'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.accent // color azul marino oscuro para modo oscuro
            : AppColors.primary, // turquesa para modo claro
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    );

  }

  Widget _buildLeaveButton(FbCommunity community) {
    return ElevatedButton.icon(
      onPressed: () => _leaveCommunity(community),
      icon: Icon(Icons.exit_to_app),
      label: Text('Abandonar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
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
    final theme = Theme.of(context);

    Icon _getCategoryIcon(String category) {
      switch (category) {
        case 'Deportes':
          return Icon(Icons.sports_soccer, color: theme.colorScheme.secondary);
        case 'Ocio':
          return Icon(Icons.movie, color: theme.colorScheme.primary);
        case 'Negocios':
          return Icon(Icons.business_center, color: theme.colorScheme.tertiary ?? Colors.orangeAccent);
        case 'Libros':
          return Icon(Icons.menu_book, color: Colors.brown.shade300);
        default:
          return Icon(Icons.category, color: theme.disabledColor);
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('comunidades').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));

                final allCommunities = snapshot.data!.docs.map((doc) =>
                    FbCommunity.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

                final filteredCommunities = allCommunities.where((community) =>
                !community.uidParticipants.contains(currentUserId) &&
                    community.uidCreator != currentUserId &&
                    (selectedCategory.isEmpty || selectedCategory == 'Todas' || community.category == selectedCategory) &&
                    (searchName.isEmpty || community.name.toLowerCase().contains(searchName.toLowerCase()))
                ).toList();

                final displayedCommunities = (selectedCategory.isEmpty || selectedCategory == 'Todas') && searchName.isEmpty
                    ? filteredCommunities.take(5).toList()
                    : filteredCommunities;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contenedor de búsqueda adaptado
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Buscar comunidades",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Escribe el nombre...',
                                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.colorScheme.primaryContainer),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchName = value;
                                });
                              },
                              style: TextStyle(color: theme.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Filtrar por categoría:",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.colorScheme.primaryContainer),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
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
                                      Text(
                                        category,
                                        style: TextStyle(color: theme.colorScheme.onSurface),
                                      ),
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
                                      Text(
                                        category,
                                        style: TextStyle(color: theme.colorScheme.onSurface),
                                      ),
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
        backgroundColor: theme.colorScheme.secondary,
        child: const Icon(Icons.add),
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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Crear Comunidad',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
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
                            final dialogTheme = Theme.of(context);
                            final dialogColorScheme = dialogTheme.colorScheme;
                            final dialogTextTheme = dialogTheme.textTheme;

                            return AlertDialog(
                              backgroundColor: dialogColorScheme.surface,
                              title: Text(
                                "Seleccionar Imagen",
                                style: dialogTextTheme.titleLarge?.copyWith(color: dialogColorScheme.onSurface),
                              ),
                              content: Text(
                                "¿Quieres tomar una foto o seleccionar de la galería?",
                                style: dialogTextTheme.bodyMedium?.copyWith(color: dialogColorScheme.onSurface.withOpacity(0.7)),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                                  child: Text(
                                    "Tomar Foto",
                                    style: TextStyle(color: dialogColorScheme.primary),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                                  child: Text(
                                    "Seleccionar de la Galería",
                                    style: TextStyle(color: dialogColorScheme.primary),
                                  ),
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
                          color: colorScheme.onSurface.withOpacity(0.1),
                          child: imageBytes != null
                              ? Image.memory(imageBytes!, fit: BoxFit.cover)
                              : Icon(Icons.camera_alt, size: 40, color: colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Nombre de la comunidad',
                        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        fillColor: colorScheme.surfaceVariant,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Descripción de la comunidad',
                        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        fillColor: colorScheme.surfaceVariant,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: colorScheme.surface,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                      ),
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
                          child: Text(category, style: TextStyle(color: colorScheme.onSurface)),
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
              child: Text('Cancelar', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty && description.isNotEmpty) {
                  _createCommunity(name, description, selectedCategory, selectedImage);
                  Navigator.pop(context);
                }
              },
              child: Text('Crear', style: TextStyle(color: colorScheme.onPrimary)),
            ),
          ],
        );
      },
    );
  }



}
