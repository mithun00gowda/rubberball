import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/screens/auth/login_screen.dart';
import 'package:rubberball/services/auth_service.dart';

import '../../root_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AuthUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Loading State (Checking auth on startup)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Error State (Optional safety)
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong with Authentication")),
          );
        }

        // 3. Authenticated State -> Show App
        if (snapshot.hasData) {
          return const RootScreen();
        }

        // 4. Unauthenticated State -> Show Login
        return const LoginScreen();
      },
    );
  }
}