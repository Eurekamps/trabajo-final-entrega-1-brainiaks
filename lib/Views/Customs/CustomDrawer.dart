import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    if (DataHolder().userProfile != null) {
      _profileLoadedFuture = Future.value(true);
    } else {
      _profileLoadedFuture = Future.value(false);
    }
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
          return Center(
            child: const Text(
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
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: userProfile.imagenURL != null
                            ? NetworkImage(userProfile.imagenURL!)
                            : AssetImage('assets/images/default_avatar.jpg')
                        as ImageProvider,
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
                  onTap: () {
                    Navigator.pop(context);
                  },
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