import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/features/auth/data/auth_repository_impl.dart';
import 'package:langkah/features/auth/domain/auth_repository.dart';
import 'package:langkah/features/auth/presentation/auth_gate.dart';
import 'package:langkah/features/auth/presentation/auth_view_model.dart';
import 'package:provider/provider.dart';

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
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(
            repository: ctx.read<AuthRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Langkah',
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(
          colorSchemeSeed: AppColors.tealPrimary,
          scaffoldBackgroundColor: AppColors.canvasLight,
          fontFamily: 'Roboto',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
