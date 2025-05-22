
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:triboo/Views/HomeView.dart';
import 'package:triboo/Views/HomerView.dart';
import 'package:triboo/Views/LoginView.dart';
import 'package:triboo/Views/ProfileUserView.dart';
import 'package:triboo/Views/RegisterView.dart';
import 'package:triboo/Views/SplashView.dart';

import '../Theme/AppTheme.dart';
import '../localization/app_localizations.dart';


class Triboo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);  // Para el cambio de fondo entre claro y oscuro

    // Hay que definir un array de rutas
    Map<String,Widget Function(BuildContext)> rutasNavegacion ={
      '/SplashView':(context)=> SplashView(),
      '/LoginView':(context)=> LoginView(),
      '/HomeView':(context)=>  HomerView(),
      '/RegisterView':(context) => RegisterView(),
      '/ProfileUserView':(context) => ProfileUserView(),
    };

    MaterialApp app = MaterialApp(title: "Triboo",

      routes: rutasNavegacion,
      initialRoute: '/SplashView',

      // 👇 CAMBIADO: uso de temas personalizados
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      debugShowCheckedModeBanner: false, // Oculta el banner de debug

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Inglés
        Locale('es', 'ES'), // Español
        // Agrega más locales si es necesario
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
    );

    return app;
  }
}
class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    isDarkMode = isDark;
    notifyListeners();
  }
}