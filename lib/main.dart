import 'package:flutter/material.dart';

import 'src/ui/home_screen.dart';

void main() {
  runApp(const SudokuHelperApp());
}

class SudokuHelperApp extends StatelessWidget {
  const SudokuHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1D6B63);
    return MaterialApp(
      title: '数独助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
