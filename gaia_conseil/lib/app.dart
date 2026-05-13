import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';

class GaiaApp extends StatelessWidget {
  const GaiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAÏA-Conseil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}
