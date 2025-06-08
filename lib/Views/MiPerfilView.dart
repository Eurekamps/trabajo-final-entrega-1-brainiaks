import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Statics/DataHolder.dart';

class MiPerfilView extends StatelessWidget {
  const MiPerfilView({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _getPerfilData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(DataHolder.currentUserId)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getPerfilData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se pudo cargar el perfil'));
          }

          final data = snapshot.data!;
          return Center(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(data['imagenURL'] ?? ''),
                    backgroundColor: theme.dividerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['nombre'] ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${data['apodo'] ?? ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cumpleaños: ${data['cumpleaños'] ?? ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // Acción para editar perfil
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Acción para cerrar sesión
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Salir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: theme.colorScheme.background,
    );
  }
}
