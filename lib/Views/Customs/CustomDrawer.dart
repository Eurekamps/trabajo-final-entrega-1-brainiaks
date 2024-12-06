import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Statics/DataHolder.dart';
import '../LoginView.dart';
import '../Statics/DataHolder.dart';
import '../Views/ChangeProfileView.dart';
import '../Views/LoginView.dart';
import 'CustomConfiguration.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obtener el ID del usuario actual desde Firebase Authentication
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Si no hay un usuario autenticado, mostramos un indicador de carga
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Usamos un FutureBuilder para cargar el perfil del usuario desde Firestore
    return FutureBuilder<bool>(
      future: _loadUserProfile(userId), // Llamamos a una función auxiliar para cargar el perfil
      builder: (context, snapshot) {
        // Mientras se cargan los datos, mostramos un indicador de progreso
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si ocurre un error al cargar los datos
        else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar el perfil: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Si el perfil no se encuentra o `AdminProfile` es null
        else if (snapshot.data == false || DataHolder().AdminProfile == null) {
          return Center(
            child: const Text(
              'No se encontró el perfil del usuario.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Si los datos se cargaron correctamente, construimos el Drawer
        else {
          final userProfile = DataHolder().AdminProfile!; // Perfil del usuario cargado

          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Encabezado del Drawer con la información del usuario
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen de perfil (predeterminada si no hay URL)
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: userProfile.imagenURL != null
                            ? NetworkImage(userProfile.imagenURL!)
                            : AssetImage('assets/images/default_avatar.jpg')
                        as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      // Apodo del usuario
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
                // Opciones del menú
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Inicio'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el Drawer
                    // Aquí puedes navegar a la pantalla inicial
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el Drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeProfileView(),
                      ),
                    ); // Navega a la vista de perfil
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el Drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomConfiguration(),
                      ),
                    ); // Navega a la vista de configuración
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar Sesión'),
                  onTap: () async {
                    // Cierra la sesión de Firebase Authentication
                    await FirebaseAuth.instance.signOut();

                    // Redirige al LoginView
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

  // Función auxiliar para cargar el perfil del usuario
  Future<bool> _loadUserProfile(String userId) async {
    try {
      // Llamamos al método de DataHolder para cargar el perfil
      bool result = await DataHolder().getUserProfile(userId);
      return result;
    } catch (e) {
      print('Error al cargar el perfil: $e');
      return false;
    }
  }
}