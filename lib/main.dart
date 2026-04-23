import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC41230),
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('HidroBalance'))),
    );
  }
}
