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
    final postsSnapshot = await DataHolder().fbAdmin.fetchFBDataList(
      collectionPath: 'comunidades/$communityId/posts',
    );

    if (mounted) {
      setState(() {
        _posts = postsSnapshot?.map((doc) {
          return FBPost.fromFirestore(doc, null);
        }).toList() ?? [];
        _isLoading = false;
      });
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
    final itemWidth = 80.0;

    return Container(
      width: itemWidth,
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo de la comunidad con borde
          GestureDetector(
            onTap: () => _onCommunitySelected(index),
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
          ),

          // Nombre de la comunidad
          SizedBox(height: 6),
          Container(
            width: itemWidth - 8, // Ancho ligeramente menor para margen
            child: Text(
              community.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del post (sin los tres puntos)
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar con inicial
                Container(
                  width: 32,
                  height: 32,
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
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.autorApodo,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Se ha eliminado el IconButton de los tres puntos
              ],
            ),
          ),

          // Imagen solo si existe
          if (post.imagenURL != null && post.imagenURL!.isNotEmpty)
            ConstrainedBox(
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
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

          // Contenido del post
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.texto,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  _formatDate(post.fechaCreacion),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
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

    setState(() {
      _selectedCommunityIndex = index;
      _posts = [];
    });
    _loadPosts();
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