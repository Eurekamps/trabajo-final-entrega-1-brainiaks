import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../FBObjects/FbCommunity.dart';
import '../Statics/DataHolder.dart';
import '../Statics/FirebaseAdmin.dart';

class CommunityView extends StatefulWidget {
  @override
  _CommunityViewState createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  final FirebaseAdmin _firebaseAdmin = DataHolder().fbAdmin;
  String currentUserId = "";
  bool _isLoading = true;

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
  Future<void> _createCommunity(String name, String description) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('comunidades').doc();
      final newId = docRef.id;

      final newCommunity = FbCommunity(
        id: newId,
        uidCreator: currentUserId,
        uidModders: '',
        uidParticipants: [], // Lista vacía - el creador no se agrega automáticamente como participante
        name: name,
        description: description,
        avatar: '',
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

  // Resto de los métodos permanecen exactamente igual...
  Future<void> _updateCommunity(String id, String newName, String newDescription) async {
    try {
      final communityToUpdate = DataHolder().allCommunities.firstWhere((community) => community.id == id);

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
        docId: updatedCommunity.id,
      );

      DataHolder().updateCommunity(updatedCommunity);
      setState(() {});
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
            _buildCommunitySection(
              title: 'Comunidades Existentes',
              communities: DataHolder().allCommunities
                  .where((community) =>
              !community.uidParticipants.contains(currentUserId) &&
                  community.uidCreator != currentUserId)
                  .toList(),
              showEditAndDelete: false,
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
              onPressed: () => Navigator.pop(context),
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
}