import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityView extends StatefulWidget {
  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;

  List<Map<String, dynamic>> userCreatedCommunities = [];
  List<Map<String, dynamic>> userJoinedCommunities = [];
  List<Map<String, dynamic>> existingCommunities = [];

  @override
  void initState() {
    super.initState();
    _loadCommunities(); // Cargar las comunidades al iniciar
  }

  // Función para cargar las comunidades
  Future<void> _loadCommunities() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Comunidades creadas por el usuario (filtrado por uidCreator)
      final createdCommunitiesSnapshot = await _firestore
          .collection('comunidades')
          .where('uidCreator', isEqualTo: userId)
          .get();

      userCreatedCommunities = createdCommunitiesSnapshot.docs
          .map((doc) => {
        'id': doc.id, // Guardar el ID del documento
        ...doc.data(),
      })
          .toList();

      // Comunidades a las que el usuario se ha unido (filtrado por uidParticipants)
      final joinedCommunitiesSnapshot = await _firestore
          .collection('comunidades')
          .where('uidParticipants', arrayContains: userId)
          .get();

      userJoinedCommunities = joinedCommunitiesSnapshot.docs
          .map((doc) => {
        'id': doc.id, // Guardar el ID del documento
        ...doc.data(),
      })
          .toList();

      // Filtramos las comunidades a las que el usuario pertenece,
      // eliminando aquellas que el usuario haya creado
      userJoinedCommunities.removeWhere((community) =>
          userCreatedCommunities.any((createdCommunity) => createdCommunity['id'] == community['id'])
      );

      // Comunidades existentes: Excluimos las comunidades que el usuario ya ha creado o a las que se ha unido
      existingCommunities = createdCommunitiesSnapshot.docs
          .map((doc) => {
        'id': doc.id, // Guardar el ID del documento
        ...doc.data(),
      })
          .toList();

      existingCommunities.removeWhere((community) =>
      userJoinedCommunities.any((joinedCommunity) => joinedCommunity['id'] == community['id']) ||
          userCreatedCommunities.any((createdCommunity) => createdCommunity['id'] == community['id'])
      );

    } catch (e) {
      print("Error cargando comunidades: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para agregar una comunidad
  Future<void> _addCommunity() async {
    final newCommunity = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'uidCreator': userId,
      'uidModders': [userId], // El creador es moderador inicial
      'uidParticipants': [userId], // El creador pertenece inicialmente
      'avatar': '', // Avatar opcional
    };

    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection('comunidades').add(newCommunity);
      await _loadCommunities(); // Recargar las comunidades
      print("Comunidad creada exitosamente.");
    } catch (e) {
      print("Error al crear comunidad: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para editar una comunidad
  Future<void> _editCommunity(Map<String, dynamic> community, String docId) async {
    _nameController.text = community['name'];
    _descriptionController.text = community['description'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar Comunidad"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nombre de la Comunidad"),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Descripción"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedCommunity = {
                  'name': _nameController.text.trim(),
                  'description': _descriptionController.text.trim(),
                  'uidCreator': community['uidCreator'],
                  'uidModders': community['uidModders'],
                  'uidParticipants': community['uidParticipants'],
                  'avatar': community['avatar'],
                };

                try {
                  await _firestore.collection('comunidades').doc(docId).update(updatedCommunity);
                  await _loadCommunities(); // Recargar comunidades
                  print("Comunidad actualizada exitosamente.");
                } catch (e) {
                  print("Error al actualizar comunidad: $e");
                }
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Actualizar"),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar una comunidad
  Future<void> _deleteCommunity(String docId) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection('comunidades').doc(docId).delete();
      await _loadCommunities(); // Recargar comunidades
      print("Comunidad eliminada exitosamente.");
    } catch (e) {
      print("Error al eliminar comunidad: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Mostrar cuadro de diálogo para agregar comunidad
  void _showAddCommunityDialog() {
    _nameController.clear();
    _descriptionController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Agregar Comunidad"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nombre de la Comunidad"),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Descripción"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _addCommunity();
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comunidades"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // Sección de comunidades creadas por el usuario
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Mis Comunidades",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          userCreatedCommunities.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No has creado ninguna comunidad."),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: userCreatedCommunities.length,
            itemBuilder: (context, index) {
              final community = userCreatedCommunities[index];
              final docId = community['id'];

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage('assets/community_placeholder.png'),
                  ),
                  title: Text(community['name']),
                  subtitle: Text(community['description']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editCommunity(community, docId),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCommunity(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Sección de comunidades a las que el usuario se ha unido (excluyendo las que ha creado)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Comunidades a las que perteneces",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          userJoinedCommunities.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No perteneces a ninguna comunidad."),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: userJoinedCommunities.length,
            itemBuilder: (context, index) {
              final community = userJoinedCommunities[index];
              final docId = community['id'];

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage('assets/community_placeholder.png'),
                  ),
                  title: Text(community['name']),
                  subtitle: Text(community['description']),
                ),
              );
            },
          ),

          // Sección de comunidades existentes
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Comunidades Existentes",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          existingCommunities.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No hay comunidades disponibles."),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: existingCommunities.length,
            itemBuilder: (context, index) {
              final community = existingCommunities[index];
              final docId = community['id'];

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage('assets/community_placeholder.png'),
                  ),
                  title: Text(community['name']),
                  subtitle: Text(community['description']),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      // Unirse a la comunidad
                      final updatedCommunity = {
                        'uidParticipants': FieldValue.arrayUnion([userId]),
                      };

                      try {
                        await _firestore
                            .collection('comunidades')
                            .doc(docId)
                            .update(updatedCommunity);
                        await _loadCommunities(); // Recargar comunidades
                        print("Te uniste a la comunidad.");
                      } catch (e) {
                        print("Error al unirse a la comunidad: $e");
                      }
                    },
                    child: Text("Unirse"),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCommunityDialog,
        child: Icon(Icons.add),
        tooltip: "Crear Comunidad",
      ),
    );
  }
}







