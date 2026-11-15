import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MotoFindApp());
}

class MotoFindApp extends StatelessWidget {
  const MotoFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'MotoFind',

      theme: AppTheme.lightTheme,

      home: const LoginScreen(),
    );
  }
}