import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Apps/Triboo.dart';
import '../../Theme/AppColors.dart';

class CustomConfiguration extends StatefulWidget {
  @override
  _CustomConfigurationState createState() => _CustomConfigurationState();
}

class _CustomConfigurationState extends State<CustomConfiguration> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        iconTheme: IconThemeData(color: isDark ? AppColors.darkText : AppColors.lightText),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.lock, color: theme.iconTheme.color),
              title: Text('Cambiar Contraseña', style: theme.textTheme.bodyMedium),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                );
              },
            ),
            Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),

            ListTile(
              leading: Icon(Icons.notifications, color: theme.iconTheme.color),
              title: Text('Notificaciones', style: theme.textTheme.bodyMedium),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
                );
              },
            ),
            Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),

            ListTile(
              leading: Icon(Icons.color_lens, color: theme.iconTheme.color),
              title: Text('Cambiar Tema', style: theme.textTheme.bodyMedium),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      title: Text('Selecciona un Tema', style: theme.textTheme.titleLarge?.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      )),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            title: Text('Claro', style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            )),
                            onTap: () {
                              Provider.of<ThemeProvider>(context, listen: false).setTheme(false);
                              Navigator.of(context).pop();
                            },
                          ),
                          ListTile(
                            title: Text('Oscuro', style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            )),
                            onTap: () {
                              Provider.of<ThemeProvider>(context, listen: false).setTheme(true);
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
                          child: Text('Cerrar', style: TextStyle(color: AppColors.primary)),
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