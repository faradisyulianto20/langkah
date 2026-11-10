import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/presentation/home/home_screen.dart';

void main() {
  runApp(const LangkahApp());
}

class LangkahApp extends StatelessWidget {
  const LangkahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Langkah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.tealPrimary,
        scaffoldBackgroundColor: AppColors.canvasBg,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
