import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triboo/Apps/Triboo.dart';
import 'firebase_options.dart';
import 'package:triboo/Views/SplashView.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Triboo());
}
