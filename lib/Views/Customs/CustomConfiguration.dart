import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Apps/MyApp.dart';


class CustomConfiguration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección para cambiar la contraseña
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Cambiar Contraseña'),
              onTap: () {
                // Navegar a la pantalla de cambio de contraseña
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                );
              },
            ),
            const Divider(),

            // Otras opciones de configuración
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificaciones'),
              onTap: () {
                // Navegar a la configuración de notificaciones
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
                );
              },
            ),
            const Divider(),

            // Opción para cambiar el tema de la aplicación
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Cambiar Tema'),
              onTap: () {
                // Lógica para cambiar el tema
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Selecciona un Tema'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            title: const Text('Claro'),
                            onTap: () {
                              // Cambiar a tema claro
                              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                              Navigator.of(context).pop();
                            },
                          ),
                          ListTile(
                            title: const Text('Oscuro'),
                            onTap: () {
                              // Cambiar a tema oscuro
                              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cerrar'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
      ),
      body: Center(
        child: Text('Aquí puedes cambiar la contraseña'),
      ),
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Notificaciones'),
      ),
      body: Center(
        child: Text('Aquí puedes ajustar las notificaciones'),
      ),
    );
  }
}