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

  Future<void> _createCommunity(String name, String description) async {
    try {
      final newCommunity = FbCommunity(
        id: '', // ID generado por Firestore
        uidCreator: currentUserId,
        uidModders: '',
        uidParticipants: [],
        name: name,
        description: description,
        avatar: '', // Puedes implementar la carga de avatar en el futuro
      );

      await _firebaseAdmin.saveFBData(
        collectionPath: 'comunidades',
        data: newCommunity.toFirestore(),
      );

      // Actualizar la lista después de crear una comunidad
      _loadCommunities();
    } catch (e) {
      print('Error al crear la comunidad: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comunidades'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _allCommunities.isEmpty
          ? Center(child: Text('No hay comunidades disponibles.'))
          : ListView.builder(
        itemCount: _allCommunities.length,
        itemBuilder: (context, index) {
          final community = _allCommunities[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(community.name),
              subtitle: Text(community.description),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCommunityDialog,
        child: Icon(Icons.add),
        tooltip: 'Crear nueva comunidad',
      ),
    );
  }
}
















