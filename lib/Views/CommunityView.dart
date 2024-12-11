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

  Future<void> _loadCommunities() async {
    // Asegúrate de tener el ID del usuario
    userId = FirebaseAuth.instance.currentUser?.uid;

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
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
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
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Lógica de eliminación de la comunidad
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Mostrar las comunidades en las que el usuario participa
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Comunidades a las que Perteneces",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          joinedCommunities.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No perteneces a ninguna comunidad."),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: joinedCommunities.length,
            itemBuilder: (context, index) {
              final community = joinedCommunities[index];
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

          // Mostrar las comunidades disponibles para unirse
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
                        await _firebaseAdmin.saveFBData(
                          collectionPath: 'comunidades',
                          data: updatedCommunity,
                          docId: docId,
                        );
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








