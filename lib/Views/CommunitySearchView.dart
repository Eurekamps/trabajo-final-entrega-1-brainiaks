import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triboo/Statics/DataHolder.dart';
import '../FBObjects/FbCommunity.dart';
import '../Statics/FirebaseAdmin.dart';

class CommunitySearchView extends StatefulWidget {
  const CommunitySearchView({Key? key}) : super(key: key);

  @override
  State<CommunitySearchView> createState() => _CommunitySearchViewState();
}

class _CommunitySearchViewState extends State<CommunitySearchView> {
  String selectedCategory = '';
  String searchName = '';
  final FirebaseAdmin _firebaseAdmin = DataHolder().fbAdmin;
  List<FbCommunity> allCommunities = [];

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    Query query = FirebaseFirestore.instance
        .collection('comunidades')
        .orderBy(FieldPath.documentId)
        .limit(20);

    final snapshot = await query.get();

    final myCommunityIds = DataHolder().myCommunities.map((c) => c.id).toSet();

    final fetched = snapshot.docs
        .map((doc) => FbCommunity.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .where((community) => !myCommunityIds.contains(community.id)) // ❌ ya unidas
        .toList();

    if (selectedCategory.isEmpty) {
      fetched.shuffle(); // aleatorio solo si "Todas"
    }

    setState(() {
      allCommunities = fetched;
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = allCommunities.where((community) {
      final matchesName = searchName.isEmpty || community.name.toLowerCase().contains(searchName.toLowerCase());
      final matchesCategory = selectedCategory.isEmpty || community.category == selectedCategory;
      return matchesName && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _loadCommunities,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _buildSearchBar(theme),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final community = filtered[index];
                  return _buildCommunityTile(community, theme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
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
                _loadCommunities(); // volver a cargar si cambia filtro
              });
            },
            items: ['Todas', 'Deportes', 'Ocio', 'Negocios', 'Libros'].map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    Icon(Icons.category, size: 18),
                    const SizedBox(width: 8),
                    Text(category),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTile(FbCommunity community, ThemeData theme) {

    return GestureDetector(
        onTap: () => _showCommunityDialog(community),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              community.avatar.isNotEmpty
                  ? Image.network(
                community.avatar,
                fit: BoxFit.cover,
              )
                  : Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(Icons.group, size: 40, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    community.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  void _showCommunityDialog(FbCommunity community) {
    final theme = Theme.of(context);
    final TextEditingController passwordController = TextEditingController();
    bool hasPassword = community.password != null && community.password!.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              community.name,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (community.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      community.description,
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ),
                Text(
                  "Integrantes: ${community.uidParticipants.length}",
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                if (hasPassword) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancelar", style: TextStyle(color: theme.colorScheme.primary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: () {
                  if (hasPassword) {
                    if (passwordController.text.trim() == community.password!.trim()) {
                      _joinCommunity(community);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Contraseña incorrecta."),
                        backgroundColor: theme.colorScheme.error,
                      ));
                    }
                  } else {
                    _joinCommunity(community);
                    Navigator.pop(context);
                  }
                },
                child: Text('Unirse'),
              ),
            ],
          );
        });
      },
    );
  }



  Future<void> _joinCommunity(FbCommunity community) async {
    try {
      if (!community.uidParticipants.contains(DataHolder.currentUserId)) {
        community.uidParticipants.add(DataHolder.currentUserId);

        await _firebaseAdmin.saveFBData(
          collectionPath: 'comunidades',
          data: community.toFirestore(),
          docId: community.id,
        );

        // Guardar en DataHolder para que la UI lo reconozca como comunidad unida
        DataHolder().addCommunity(community);

        setState(() {}); // Refrescar la interfaz
      }
    } catch (e) {
      print('Error al unirse a la comunidad: $e');
      
    }
  }


}

