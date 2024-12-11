import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityView extends StatefulWidget {
  @override
  _CommunityViewState createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  // Lista para almacenar las comunidades
  List<QueryDocumentSnapshot> communities = [];

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  // Cargar todas las comunidades desde Firestore
  Future<void> _loadCommunities() async {
    try {
      // Obtener los documentos de la colección 'comunidades' de Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('comunidades').get();

      setState(() {
        communities = querySnapshot.docs;
      });
    } catch (e) {
      print("Error al cargar comunidades: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comunidades'),
      ),
      body: ListView.builder(
        itemCount: communities.length,
        itemBuilder: (context, index) {
          var community = communities[index].data() as Map<String, dynamic>;

          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(community['avatar'] ?? 'default_avatar_url'),
              ),
              title: Text(community['name']),
              subtitle: Text(community['description']),
            ),
          );
        },
      ),
    );
  }
}











