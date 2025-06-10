import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../FBObjects/FbCommunity.dart';
import '../Statics/DataHolder.dart';
import 'package:mime/mime.dart';

class CommunityView extends StatefulWidget {
  const CommunityView({Key? key}) : super(key: key);

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> with TickerProviderStateMixin {
  String currentUserId = "";

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allJoined = DataHolder().joinedCommunities;

    final createdByMe = DataHolder().createdCommunities;

    final moderatedByMe = allJoined.where((c) {
      final modders = c.uidModders.split(',').map((id) => id.trim()).toSet();
      return modders.contains(currentUserId);
    }).toList();

    final joinedOnly = allJoined;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          centerTitle: true,
          title: const Text(
            'COMUNIDADES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Creadas'),
              Tab(text: 'Modero'),
              Tab(text: 'Unido'),
            ],
          ),
        ),
        backgroundColor: theme.colorScheme.background,
        body: TabBarView(
          children: [
            _buildCommunityListSection("Creadas por mí", createdByMe, theme),
            _buildCommunityListSection("Comunidades que modero", moderatedByMe, theme),
            _buildCommunityListSection("Comunidades unidas", joinedOnly, theme),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateCommunityDialog,
          backgroundColor: theme.colorScheme.secondary,
          tooltip: 'Crear nueva comunidad',
          child: const Icon(Icons.add),
        ),
      ),
    );

  }

  Widget _buildCommunityListSection(String title, List<FbCommunity> communities, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: communities.isEmpty
          ? Center(
        child: Text(
          'No hay comunidades en esta sección.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ),
      )
          : ListView.builder(
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final c = communities[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: theme.colorScheme.surfaceVariant,
            child: ListTile(
              leading: ClipOval(
                child: c.avatar.isNotEmpty
                    ? Image.network(c.avatar, width: 50, height: 50, fit: BoxFit.cover)
                    : Container(
                  width: 50,
                  height: 50,
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  child: Icon(Icons.group, size: 30, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
              title: Text(
                c.name,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                c.description.isNotEmpty ? c.description : 'Sin descripción.',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title == "Creadas por mí" || title == "Comunidades que modero")
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Gestionar comunidad',
                      onPressed: () => _openCommunityAdminPanel(c, title == "Creadas por mí"),
                    ),
                  IconButton(
                    icon: Icon(
                      title == "Creadas por mí" ? Icons.delete_outline : Icons.exit_to_app,
                      color: title == "Creadas por mí" ? Colors.red : theme.colorScheme.primary,
                    ),
                    tooltip: title == "Creadas por mí" ? 'Eliminar' : 'Abandonar',
                    onPressed: () {
                      if (title == "Creadas por mí") {
                        _confirmDeleteCommunity(c);
                      } else {
                        _confirmLeaveCommunity(c);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Future<void> _confirmDeleteCommunity(FbCommunity community) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comunidad'),
        content: Text('¿Estás seguro de que deseas eliminar "${community.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DataHolder().deleteCommunityFromFirebase(community.id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunidad eliminada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar comunidad: $e')),
        );
      }
    }

  }

  Future<void> _confirmLeaveCommunity(FbCommunity community) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonar comunidad'),
        content: Text('¿Quieres abandonar la comunidad "${community.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DataHolder().leaveCommunity(community);
      setState(() {}); // Refresca la UI si es necesario
    }
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

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Crear Comunidad',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final ImageSource? source = await showDialog<ImageSource>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Seleccionar imagen'),
                            content: const Text('¿Desde dónde quieres obtener la imagen?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, ImageSource.camera),
                                child: const Text('Cámara'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                                child: const Text('Galería'),
                              ),
                            ],
                          ),
                        );

                        if (source != null) {
                          final file = await ImagePicker().pickImage(source: source);
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
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
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
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCommunity(String name, String description, String category, XFile? imageFile) async {
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

      await FirebaseFirestore.instance
          .collection('comunidades')
          .doc(newId)
          .set(newCommunity.toFirestore());

      DataHolder().addCommunity(newCommunity);
      setState(() {}); // refrescar UI
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

  void _openCommunityAdminPanel(FbCommunity c, bool isCreator) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: Text(c.name),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(tabs: [Tab(text: 'Detalles'), Tab(text: 'Miembros')]),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(c, isCreator),
                        _buildMembersTab(c, isCreator),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab(FbCommunity c, bool editable) {
    final nameCtl = TextEditingController(text: c.name);
    final descCtl = TextEditingController(text: c.description);

    return Column(
      children: [
        TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Nombre')),
        SizedBox(height: 12),
        TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Descripción')),
        if (editable) SizedBox(height: 20),
        if (editable)
          ElevatedButton(
            onPressed: () {
              c.name = nameCtl.text.trim();
              c.description = descCtl.text.trim();
              FirebaseFirestore.instance
                  .collection('comunidades')
                  .doc(c.id)
                  .update({'name': c.name, 'description': c.description});
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detalles actualizados')));
            },
            child: const Text('Guardar cambios'),
          ),
      ],
    );
  }

  Widget _buildMembersTab(FbCommunity c, bool editable) {
    final modders = c.uidModders.split(',').map((e) => e.trim()).toSet();

    return ListView(
      children: c.uidParticipants.map((uid) {
        final isMod = modders.contains(uid);
        return ListTile(
          title: Text(uid),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMod)
                Chip(label: Text('Mod')),
              if (editable && !isMod)
                TextButton(
                  onPressed: () {
                    modders.add(uid);
                    c.uidModders = modders.join(',');
                    FirebaseFirestore.instance
                        .collection('comunidades')
                        .doc(c.id)
                        .update({'uidModders': c.uidModders});
                    setState(() {});
                  },
                  child: const Text('Hacer mod'),
                ),
              if (editable)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    c.uidParticipants.remove(uid);
                    FirebaseFirestore.instance
                        .collection('comunidades')
                        .doc(c.id)
                        .update({'uidParticipants': c.uidParticipants});
                    setState(() {});
                  },
                ),
            ],
          ),
        );
      }).toList(),
    );
  }



}