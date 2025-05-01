import 'package:firebase_auth/firebase_auth.dart';
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
    // Inicializamos los estados de like y reporte directamente en el widget
    bool isLiked = post.likes > 0;
    bool isReported = post.reportes > 0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (post.autorImagenURL != null && post.autorImagenURL!.isNotEmpty)
                          ? NetworkImage(post.autorImagenURL!)
                          : null,
                      child: (post.autorImagenURL == null || post.autorImagenURL!.isEmpty)
                          ? Text(
                        post.autorApodo.isNotEmpty ? post.autorApodo[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.autorApodo,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatDate(post.fechaCreacion),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Texto
              if (post.texto.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    post.texto,
                    style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800]),
                  ),
                ),

              // Tags
              if (post.tags != null && post.tags!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Imagen
              if (post.imagenURL != null && post.imagenURL!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                    ),
                    child: Image.network(
                      post.imagenURL!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Icon(Icons.broken_image, color: Colors.grey[400]));
                      },
                    ),
                  ),
                ),

              // Botones de Like y Reportar
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Botón de Like
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                        color: isLiked ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () async {
                        setState(() {
                          if (isLiked) {
                            post.likes -= 1; // Disminuir el contador
                          } else {
                            post.likes += 1; // Aumentar el contador
                          }
                          isLiked = !isLiked;
                        });

                        // Actualizamos el contador de likes en Firestore
                        await FirebaseFirestore.instance
                            .collection('comunidades')
                            .doc(myComunitys[_selectedCommunityIndex].id) // Usar myComunitys[_selectedCommunityIndex] en lugar de widget.community
                            .collection('posts')
                            .doc(post.id)
                            .update({'likes': post.likes});

                      },
                    ),
                    Text('${post.likes} Likes'),

                    Spacer(),

                    // Botón de Reportar
                    if (!isReported) // Solo mostramos el botón si no ha sido reportado
                      IconButton(
                        icon: Icon(
                          Icons.report_problem,
                          color: Colors.grey,
                        ),
                        onPressed: () async {
                          bool? confirmReport = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('¿Estás seguro?'),
                              content: Text('¿Quieres reportar este post?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text('Reportar'),
                                ),
                              ],
                            ),
                          );

                          if (confirmReport == true) {
                            setState(() {
                              isReported = true; // Cambiamos el estado a reportado
                            });

                            // Aumentamos el contador de reportes en Firestore
                            await FirebaseFirestore.instance
                                .collection('comunidades')
                                .doc(myComunitys[_selectedCommunityIndex].id) // Usar myComunitys[_selectedCommunityIndex] en lugar de widget.community
                                .collection('posts')
                                .doc(post.id)
                                .update({
                              'reportes': FieldValue.increment(1), // Aumentamos el contador
                            });


                            // Después de reportar, el botón desaparece
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
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