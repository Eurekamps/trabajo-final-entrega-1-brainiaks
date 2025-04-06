import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triboo/FBObjects/FbCommunity.dart';
import 'package:triboo/FBObjects/FBPost.dart';
import 'package:triboo/Statics/DataHolder.dart';
import 'package:triboo/Views/CreatePostView.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late List<FbCommunity> myComunitys = DataHolder().myCommunities;
  int _selectedCommunityIndex = 0;
  List<FBPost> _posts = [];
  bool _isLoading = false;
  final ScrollController _storiesController = ScrollController();

  @override
  void initState() {
    super.initState();
    myComunitys = [
      ...DataHolder().createdCommunities,
      ...DataHolder().joinedCommunities.where(
              (joined) => !DataHolder().createdCommunities.any(
                  (created) => created.id == joined.id
          )
      )
    ];
    _loadPosts();
  }

  @override
  void dispose() {
    _storiesController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (myComunitys.isEmpty) return;

    setState(() => _isLoading = true);
    final communityId = myComunitys[_selectedCommunityIndex].id;
    print("Cargando posts de comunidad ID: $communityId"); // Debug

    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('comunidades')
          .doc(communityId)
          .collection('posts')
          .orderBy('fechaCreacion', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _posts = postsSnapshot.docs.map((doc) {
            return FBPost.fromFirestore(doc, null);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando posts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Triboo'),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Sección de Comunidades (Historias)
          _buildCommunitiesStories(),

          // Divisor
          Divider(height: 1, thickness: 1),

          // Sección de Posts
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildCommunitiesStories() {
    // Combinar comunidades creadas y unidas (sin duplicados)
    final combinedCommunities = [
      ...DataHolder().createdCommunities,
      ...DataHolder().joinedCommunities.where(
              (joined) => !DataHolder().createdCommunities.any(
                  (created) => created.id == joined.id
          )
      )
    ];

    if (combinedCommunities.isEmpty) return SizedBox.shrink();

    return Container(
      height: 110,
      child: ListView.builder(
        controller: _storiesController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: combinedCommunities.length,
        itemBuilder: (context, index) {
          return _buildStoryItem(combinedCommunities[index], index);
        },
      ),
    );
  }
  Widget _buildStoryItem(FbCommunity community, int index) {
    final isSelected = _selectedCommunityIndex == index;

    return GestureDetector( // Envuelve todo el contenido en un GestureDetector
      onTap: () => _onCommunitySelected(index),
      child: SizedBox(
        width: 84,
        height: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar con borde
            Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(colors: [Colors.blue, Colors.purple])
                    : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(community.avatar),
                ),
              ),
            ),

            SizedBox(height: 6),

            // Nombre de la comunidad
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                community.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay posts en esta comunidad',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 20),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostItem(_posts[index]);
        },
      ),
    );
  }

  Widget _buildPostItem(FBPost post) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del post
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar con inicial (mejorado)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      post.autorApodo.isNotEmpty
                          ? post.autorApodo[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.autorApodo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(post.fechaCreacion),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido del post (con márgenes ajustados)
          if (post.texto.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                post.texto,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),

          // Tags (nuevo)
          if (post.tags != null && post.tags!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: post.tags!.map((tag) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Imagen (con bordes redondeados)
          if (post.imagenURL != null && post.imagenURL!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Image.network(
                  post.imagenURL!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[100],
                      child: Center(
                        child: Icon(Icons.broken_image,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Ahora mismo';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _onCommunitySelected(int index) {
    if (_selectedCommunityIndex == index) return;
    print("Comunidad seleccionada: ${myComunitys[index].id}"); // Debug

    setState(() {
      _selectedCommunityIndex = index;
      _posts = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPosts());
  }

  void _navigateToCreatePost() {
    if (myComunitys.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostView(
          community: myComunitys[_selectedCommunityIndex],
        ),
      ),
    ).then((_) => _loadPosts());
  }
}