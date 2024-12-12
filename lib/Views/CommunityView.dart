import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';

import '../FBObjects/FbCommunity.dart';
import '../Statics/FirebaseAdmin.dart';

class CommunityView extends StatefulWidget {
  @override
  _CommunityViewState createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  final FirebaseAdmin _firebaseAdmin = FirebaseAdmin();
  String currentUserId = ""; // Variable para almacenar el UID del usuario actual
  List<FbCommunity> _allCommunities = [];
  List<FbCommunity> _createdCommunities = [];
  List<FbCommunity> _joinedCommunities = [];
  bool _isLoading = true; // Indica si los datos están cargando

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid; // Asignar el UID del usuario actual
      _loadCommunities();
    } else {
      print('No hay usuario autenticado');
    }
  }

  Future<void> _loadCommunities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshots = await _firebaseAdmin.fetchFBDataList(
        collectionPath: 'comunidades',
      );

      if (snapshots != null) {
        setState(() {
          _allCommunities = snapshots
              .map((doc) => FbCommunity.fromFirestore(doc))
              .toList();

          _createdCommunities = _allCommunities
              .where((community) => community.uidCreator == currentUserId)
              .toList();

          _joinedCommunities = _allCommunities
              .where((community) =>
          community.uidParticipants.contains(currentUserId) &&
              community.uidCreator != currentUserId)
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar las comunidades: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCommunity(String id) async {
    try {
      await _firebaseAdmin.deleteFBData(
        collectionPath: 'comunidades',
        docId: id,
      );
      _loadCommunities(); // Recargar comunidades después de borrar
    } catch (e) {
      print('Error al eliminar la comunidad: $e');
    }
  }

  Future<void> _updateCommunity(String id, String newName, String newDescription) async {
    try {
      final communityToUpdate = _allCommunities.firstWhere((community) => community.id == id);

      final updatedCommunity = FbCommunity(
        id: communityToUpdate.id,
        uidCreator: communityToUpdate.uidCreator,
        uidModders: communityToUpdate.uidModders,
        uidParticipants: communityToUpdate.uidParticipants,
        name: newName,
        description: newDescription,
        avatar: communityToUpdate.avatar,
      );

      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: updatedCommunity.toFirestore(),
        docId: id,
      );

      _loadCommunities();
    } catch (e) {
      print('Error al actualizar la comunidad: $e');
    }
  }

  void _showEditCommunityDialog(FbCommunity community) {
    final nameController = TextEditingController(text: community.name);
    final descriptionController = TextEditingController(text: community.description);

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
                  _updateCommunity(community.id, newName, newDescription);
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

  void _showCreateCommunityDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Crear Comunidad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nombre de la comunidad'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Descripción de la comunidad'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty && description.isNotEmpty) {
                  _createCommunity(name, description);
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

  Future<void> _createCommunity(String name, String description) async {
    try {
      final newCommunity = FbCommunity(
        id: '', // ID generado por Firestore
        uidCreator: currentUserId,
        uidModders: '',
        uidParticipants: [],
        name: name,
        description: description,
        avatar: '',
      );

      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: newCommunity.toFirestore(),
      );

      _loadCommunities();
    } catch (e) {
      print('Error al crear la comunidad: $e');
    }
  }

  Widget _buildCommunitySection({
    required String title,
    required List<FbCommunity> communities,
    required bool showEditAndDelete,
    required Widget? actionButtons(FbCommunity community),
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
                  title: Text(community.name),
                  subtitle: Text(community.description),
                  trailing: showEditAndDelete
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showEditCommunityDialog(community),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteCommunity(community.id),
                      ),
                    ],
                  )
                      : ElevatedButton(
                    onPressed: () => _joinCommunity(community),
                    child: Text('Unirse'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _joinCommunity(FbCommunity community) async {
    try {
      community.uidParticipants.add(currentUserId);
      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: community.toFirestore(),
        docId: community.id,
      );
      _loadCommunities();
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommunitySection(
              title: 'Mis Comunidades',
              communities: _createdCommunities,
              showEditAndDelete: true, actionButtons: (FbCommunity community) {  },
            ),
            _buildCommunitySection(
              title: 'Comunidades a las que pertenezco',
              communities: _joinedCommunities,
              showEditAndDelete: false, actionButtons: (FbCommunity community) {  },
            ),
            _buildCommunitySection(
              title: 'Comunidades Existentes',
              communities: _allCommunities
                  .where((community) =>
              !community.uidParticipants.contains(currentUserId) &&
                  community.uidCreator != currentUserId)
                  .toList(),
              showEditAndDelete: false, actionButtons: (FbCommunity community) {  },
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
}





















