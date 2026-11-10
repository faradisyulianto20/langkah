import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/core/providers/theme_provider.dart';
import 'package:langkah/core/theme/app_theme.dart';
import 'package:langkah/features/auth/data/auth_repository_impl.dart';
import 'package:langkah/features/auth/domain/auth_repository.dart';
import 'package:langkah/features/auth/presentation/auth_gate.dart';
import 'package:langkah/features/auth/presentation/auth_view_model.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  // Load persisted theme preference before app starts
  final themeProvider = ThemeProvider();
  await themeProvider.loadFromPrefs();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => LangkahApp(themeProvider: themeProvider),
    ),
  );
}

class LangkahApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const LangkahApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // Auth
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(
            repository: ctx.read<AuthRepository>(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Langkah',
          debugShowCheckedModeBanner: false,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}
