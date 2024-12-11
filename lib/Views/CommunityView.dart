import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../FBObjects/FbCommunity.dart';
import '../Statics/FirebaseAdmin.dart';


class CommunityView extends StatefulWidget {
  @override
  _CommunityViewState createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  final FirebaseAdmin _firebaseAdmin = FirebaseAdmin();
  List<FbCommunity> _communities = [];

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    try {
      final snapshots = await _firebaseAdmin.fetchFBDataList(
        collectionPath: 'comunidades',
      );
      if (snapshots != null) {
        setState(() {
          _communities = snapshots.map((doc) => FbCommunity.fromFirestore(doc)).toList();
        });
      }
    } catch (e) {
      print('Error al cargar las comunidades: $e');
    }
  }

  Future<void> _createCommunity(String name, String description) async {
    try {
      final newCommunity = FbCommunity(
        id: '', // Será generado automáticamente por Firestore
        uidCreator: 'placeholder_creator', // Cambia esto al UID del usuario actual
        uidModders: 'placeholder_modders', // Ajusta esto según sea necesario
        uidParticipants: [], // Inicialmente vacío
        name: name,
        description: description,
        avatar: '', // Implementa carga de avatar más tarde si es necesario
      );

      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: newCommunity.toFirestore(),
      );

      // Recargar la lista de comunidades
      _loadCommunities();
    } catch (e) {
      print('Error al crear la comunidad: $e');
    }
  }

  void _showCreateCommunityDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

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
                decoration: InputDecoration(labelText: 'Nombre de la Comunidad'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();

                if (name.isNotEmpty && description.isNotEmpty) {
                  _createCommunity(name, description);
                  Navigator.of(context).pop();
                } else {
                  print('Por favor, completa todos los campos.');
                }
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
        title: Text('Lista de Comunidades'),
      ),
      body: ListView.builder(
        itemCount: _communities.length,
        itemBuilder: (context, index) {
          final community = _communities[index];
          return ListTile(
            title: Text(community.name),
            subtitle: Text(community.description),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCommunityDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}












