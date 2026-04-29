import 'package:flutter/material.dart';
import 'screens/auth/tela_login.dart';
import 'theme/tema_app.dart';

void main() {
  runApp(const HidroBalanceApp());
}

class HidroBalanceApp extends StatelessWidget {
  const HidroBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HidroBalance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}