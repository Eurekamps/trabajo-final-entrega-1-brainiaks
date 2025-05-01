import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Statics/DataHolder.dart';
import '../ChangeProfileView.dart';
import '../LoginView.dart';
import 'CustomConfiguration.dart';

class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late Future<bool> _profileLoadedFuture;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  void _initializeProfile() {
    // Inicializa la variable _profileLoadedFuture y obtiene el perfil
    _profileLoadedFuture = DataHolder().getUserProfile(DataHolder.currentUserId).then((profileExists) {
      if (profileExists) {
        // Si el perfil existe, actualizar la URL de la imagen
        setState(() {
          _currentImageUrl = _processImageUrl(DataHolder().userProfile?.imagenURL);
        });
      }
      return profileExists;
    });
  }

  String? _processImageUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;

    // Añadir timestamp para evitar caché en la web
    return '$originalUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _isValidImageUrl(String url) {
    // Verifica si la URL tiene una extensión válida para una imagen
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
    final uri = Uri.parse(url);
    final pathExtension = uri.path.split('.').last.toLowerCase();
    return validExtensions.contains(pathExtension);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _profileLoadedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar el perfil: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (snapshot.data == false || DataHolder().userProfile == null) {
          return const Center(
            child: Text(
              'No se encontró el perfil del usuario.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        } else {
          final userProfile = DataHolder().userProfile!;
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _currentImageUrl == null || !_isValidImageUrl(_currentImageUrl!)
                          ? const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/default_avatar.jpg'),
                      )
                          : ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _currentImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/images/default_avatar.jpg'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userProfile.apodo ?? "Sin apodo",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Inicio'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeProfileView(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomConfiguration(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar Sesión'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
