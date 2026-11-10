import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/network/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const LangkahApp(),
    ),
  );
}

class LangkahApp extends StatelessWidget {
  const LangkahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Langkah',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorSchemeSeed: AppColors.tealPrimary,
        scaffoldBackgroundColor: AppColors.canvasLight,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Langkah App — Supabase Connected'),
        ),
      ),
    );
  }
}
