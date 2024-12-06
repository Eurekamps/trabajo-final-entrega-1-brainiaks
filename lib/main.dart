import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triboo/Apps/Triboo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triboo/Views/SplashView.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: Triboo(),
  ),
  );
}


