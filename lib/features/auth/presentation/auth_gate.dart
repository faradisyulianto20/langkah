import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/features/auth/presentation/screens/login_screen.dart';
import 'package:langkah/features/home/presentation/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isInitialized) {
      return const LoginScreen();
    }

    return StreamBuilder<AuthState>(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final session = SupabaseConfig.client.auth.currentSession;
          if (session == null) {
            return const Scaffold(
              backgroundColor: AppColors.canvasLight,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealPrimary),
                ),
              ),
            );
          }
        }

        final session = SupabaseConfig.client.auth.currentSession;

        if (session != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
