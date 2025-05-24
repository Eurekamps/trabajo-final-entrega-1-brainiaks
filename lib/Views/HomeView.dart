import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import 'package:triboo/FBObjects/FbCommunity.dart';
import 'package:triboo/FBObjects/FBPost.dart';
import 'package:triboo/Statics/DataHolder.dart';
import 'package:triboo/Views/CreatePostView.dart';

import '../FBObjects/FbPerfil.dart';
import '../Theme/AppColors.dart';


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
  String? getCurrentUserId() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid; // Retorna el UID o null si no está autenticado
  }
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Sección de Comunidades (Historias)
          _buildCommunitiesStories(),

          // Divisor con estilo del tema
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor,
          ),

          // Sección de Posts
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),

      // Botón flotante estilizado
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: const Icon(Icons.add),
        backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
        foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _onCommunitySelected(index),
      child: SizedBox(
        width: 84,
        height: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar con borde usando colores del tema
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    theme.colorScheme.secondary,
                  ],
                )
                    : LinearGradient(
                  colors: [
                    theme.dividerColor.withOpacity(0.3),
                    theme.dividerColor.withOpacity(0.5),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: theme.cardColor,
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(community.avatar),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Nombre de la comunidad con estilos del tema
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                community.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : theme.textTheme.bodyMedium?.color ?? Colors.black,
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
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary, // indicador con color principal
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed,
              size: 50,
              color: theme.disabledColor, // color para iconos deshabilitados/placeholder
            ),
            const SizedBox(height: 16),
            Text(
              'No hay posts en esta comunidad',
              style: TextStyle(color: theme.disabledColor), // texto gris adaptado al tema
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: theme.colorScheme.primary, // color del spinner al refrescar
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostItem(_posts[index]);
        },
      ),
    );
  }


  Widget _buildPostItem(FBPost post) {
    String? currentUserId = getCurrentUserId();
    bool isLiked = post.likedBy.contains(currentUserId);
    bool isReported = post.reportedBy.contains(currentUserId);

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.cardColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (avatar y autor)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: (post.autorImagenURL != null && post.autorImagenURL!.isNotEmpty)
                          ? NetworkImage(post.autorImagenURL!)
                          : null,
                      child: (post.autorImagenURL == null || post.autorImagenURL!.isEmpty)
                          ? Text(
                        post.autorApodo.isNotEmpty ? post.autorApodo[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.autorApodo,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(post.fechaCreacion),
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color ?? theme.disabledColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Texto del post
              if (post.texto.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    post.texto,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),

              // Tags
              if (post.tags != null && post.tags!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: post.tags!.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
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
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    color: theme.colorScheme.surface,
                    child: Image.network(
                      post.imagenURL!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.broken_image, color: theme.disabledColor),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Botones de Like y Reportar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.redAccent : theme.disabledColor,
                      ),
                      onPressed: () async {
                        if (currentUserId == null) {
                          print("Usuario no autenticado");
                          return;
                        }

                        final postRef = FirebaseFirestore.instance
                            .collection('comunidades')
                            .doc(myComunitys[_selectedCommunityIndex].id)
                            .collection('posts')
                            .doc(post.id);

                        final postSnapshot = await postRef.get();
                        int currentLikes = postSnapshot['likes'] ?? 0;
                        List<dynamic> likedBy = postSnapshot['likedBy'] ?? [];
                        bool currentUserLiked = likedBy.contains(currentUserId);

                        if (currentUserLiked) {
                          currentLikes -= 1;
                          await postRef.update({
                            'likes': currentLikes,
                            'likedBy': FieldValue.arrayRemove([currentUserId]),
                          });
                        } else {
                          currentLikes += 1;
                          await postRef.update({
                            'likes': currentLikes,
                            'likedBy': FieldValue.arrayUnion([currentUserId]),
                          });
                        }

                        setState(() {
                          post.likes = currentLikes;
                          if (currentUserLiked) {
                            post.likedBy.remove(currentUserId);
                          } else {
                            post.likedBy.add(currentUserId);
                          }
                        });
                      },
                    ),
                    Text(
                      '${post.likes} Likes',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                    const Spacer(),

                    if (!isReported)
                      IconButton(
                        icon: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orangeAccent,
                        ),
                        onPressed: () async {
                          if (currentUserId == null) {
                            print("Usuario no autenticado");
                            return;
                          }

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
                              isReported = true;
                            });

                            try {
                              final postRef = FirebaseFirestore.instance
                                  .collection('comunidades')
                                  .doc(myComunitys[_selectedCommunityIndex].id)
                                  .collection('posts')
                                  .doc(post.id);

                              await postRef.update({
                                'reportes': FieldValue.increment(1),
                                'reportedBy': FieldValue.arrayUnion([currentUserId]),
                              });

                              setState(() {
                                post.reportedBy.add(currentUserId);
                              });
                            } catch (e) {
                              print('Error al reportar: $e');
                            }
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