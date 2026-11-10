import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
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
        colorSchemeSeed: const Color(0xFF00897B),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Langkah App'),
        ),
      ),
    );
  }
}
