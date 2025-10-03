import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_scaffold.dart';

/// AuthWrapper - Handles authentication-aware navigation
/// Listens to Firebase Auth state changes and shows appropriate screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is authenticated, show MainScaffold
        if (snapshot.hasData && snapshot.data != null) {
          return MainScaffold(key: MainScaffold.scaffoldKey);
        }

        // If user is not authenticated, show LoginScreen
        return const LoginScreen();
      },
    );
  }
}