import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/constants/app_themes.dart';
import 'package:rubberball/providers/dashboard_provider.dart';
import 'package:rubberball/providers/match_lobby_provider.dart';
import 'package:rubberball/providers/match_provider.dart';
import 'package:rubberball/providers/scoring_provider.dart';
import 'package:rubberball/providers/user_profile_provider.dart';
import 'package:rubberball/screens/auth/auth_wrapper.dart';
import 'package:rubberball/services/auth_service.dart';

import 'firebase_options.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder:(context,asyncSnapshot){
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (asyncSnapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: SelectableText(asyncSnapshot.error.toString()),
              ),
            ),
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MatchesProvider()),
            ChangeNotifierProvider(create: (_) => DashboardProvider()),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => MatchLobbyProvider()),
            ChangeNotifierProvider(create: (_) => ScoringProvider()),
          ],
          child: MaterialApp(
            title: 'Rubber Ball',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.cricketBoardTheme,
            home: AuthWrapper(),
          ),
        );
      }
    );
  }
}

