import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Statics/FirebaseAdmin.dart';

class CommunityView extends StatefulWidget {
  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  final FirebaseAdmin _firebaseAdmin = FirebaseAdmin();
  List<Map<String, dynamic>> createdCommunities = [];
  List<Map<String, dynamic>> joinedCommunities = [];
  List<Map<String, dynamic>> existingCommunities = [];

  String? userId;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  // Cargar comunidades
  Future<void> _loadCommunities() async {
    // Asegúrate de tener el ID del usuario
    userId = FirebaseAuth.instance.currentUser?.uid;

    // Verificar que userId no sea null
    if (userId == null) {
      print("Error: Usuario no autenticado");
      return;
    }

    // Cargar las comunidades creadas por el usuario
    var createdCommunitiesData = await _firebaseAdmin.fetchFBDataList(
      collectionPath: 'comunidades',
      filters: Filter('uidCreador', isEqualTo: userId),
    );
    setState(() {
      createdCommunities = createdCommunitiesData?.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
    });

    // Cargar las comunidades en las que el usuario está participando
    var joinedCommunitiesData = await _firebaseAdmin.fetchFBDataList(
      collectionPath: 'comunidades',
      filters: Filter('uidParticipants', arrayContains: userId),
    );
    setState(() {
      joinedCommunities = joinedCommunitiesData?.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
    });

    // Cargar todas las comunidades disponibles
    var allCommunitiesData = await _firebaseAdmin.fetchFBDataList(
      collectionPath: 'comunidades',
    );
    setState(() {
      existingCommunities = allCommunitiesData?.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
    });

    // Filtrar las comunidades que no han sido creadas por el usuario ni a las que ya pertenece
    existingCommunities.removeWhere((community) => createdCommunities.contains(community) || joinedCommunities.contains(community));
  }

  // Mostrar el cuadro de diálogo para crear una comunidad
  void _showAddCommunityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String communityName = '';
        String communityDescription = '';

        return AlertDialog(
          title: Text('Crear Comunidad'),
          content: Column(
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Nombre de la Comunidad'),
                onChanged: (value) {
                  setState(() {
                    communityName = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Descripción'),
                onChanged: (value) {
                  setState(() {
                    communityDescription = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el cuadro de diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Verificar que el usuario esté autenticado antes de proceder
                if (userId == null) {
                  print("Error: Usuario no autenticado");
                  Navigator.pop(context); // Cerrar el cuadro de diálogo
                  return;
                }

                // Asignar valores predeterminados si los campos están vacíos
                communityName = communityName.isEmpty ? 'Comunidad Sin Nombre' : communityName;
                communityDescription = communityDescription.isEmpty ? 'Sin Descripción' : communityDescription;

                // Crear comunidad
                final communityData = {
                  'name': communityName,
                  'description': communityDescription,
                  'uidCreador': userId,
                  'uidParticipants': [userId],  // El creador es el primer participante
                };

                await _firebaseAdmin.saveFBData(
                  collectionPath: 'comunidades',
                  data: communityData,
                );
                await _loadCommunities(); // Recargar las comunidades después de crearla
                Navigator.pop(context); // Cerrar el cuadro de diálogo
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar comunidad
  void _deleteCommunity(String docId) async {
    try {
      await _firebaseAdmin.deleteFBData(
        collectionPath: 'comunidades',
        docId: docId,
      );
      await _loadCommunities();  // Recargar las comunidades
      print("Comunidad eliminada.");
    } catch (e) {
      print("Error al eliminar la comunidad: $e");
    }
  }

  // Función para editar comunidad
  void _editCommunity(String docId, String communityName, String communityDescription) async {
    showDialog(
      context: context,
      builder: (context) {
        String updatedName = communityName;
        String updatedDescription = communityDescription;

        return AlertDialog(
          title: Text('Editar Comunidad'),
          content: Column(
            children: [
              TextField(
                controller: TextEditingController(text: updatedName),
                decoration: InputDecoration(labelText: 'Nombre de la Comunidad'),
                onChanged: (value) {
                  updatedName = value;
                },
              ),
              TextField(
                controller: TextEditingController(text: updatedDescription),
                decoration: InputDecoration(labelText: 'Descripción'),
                onChanged: (value) {
                  updatedDescription = value;
                },
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
            TextButton(
              onPressed: () async {
                final updatedData = {
                  'name': updatedName,
                  'description': updatedDescription,
                };

                try {
                  await _firebaseAdmin.saveFBData(
                    collectionPath: 'comunidades',
                    data: updatedData,
                    docId: docId,
                  );
                  await _loadCommunities();  // Recargar las comunidades
                  Navigator.pop(context);  // Cerrar el cuadro de diálogo
                  print("Comunidad editada.");
                } catch (e) {
                  print("Error al editar la comunidad: $e");
                }
              },
              child: Text('Actualizar'),
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
        title: Text('Comunidades'),
      ),
      body: ListView(
        children: [
          // Mostrar las comunidades creadas por el usuario
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Mis Comunidades",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          createdCommunities.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No has creado ninguna comunidad."),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: createdCommunities.length,
            itemBuilder: (context, index) {
              final community = createdCommunities[index];
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
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Lógica de edición de la comunidad
                          _editCommunity(community['id'], community['name'], community['description']);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Lógica de eliminación de la comunidad
                          _deleteCommunity(community['id']);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Similar para las demás listas: comunidades unidas, comunidades existentes
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









