import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'checkin_screen.dart';
import 'checkin_history_screen.dart';
import 'auth_wrapper.dart'; // Import the auth wrapper
import 'ui/theme/theme.dart'; // Import our custom theme
import 'ui/components/components.dart'; // Import components with transitions

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLife - Monochromatic Minimalism',
      theme: FitLifeTheme.themeData, // Use our monochromatic minimalism theme
      home: const AuthWrapper(), // Use auth-aware navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/workout': (context) => const WorkoutScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/checkin': (context) => const CheckInScreen(),
        '/checkin-history': (context) => const CheckInHistoryScreen(),
      },
      onGenerateRoute: (settings) {
        // Custom transitions for different routes
        switch (settings.name) {
          case '/login':
          case '/register':
            return FitLifeTransitions.authTransition(LoginScreen());
          case '/workout':
            return FitLifeTransitions.slideRightToLeft(WorkoutScreen());
          case '/progress':
            return FitLifeTransitions.fadeScale(ProgressScreen());
          case '/profile':
            return FitLifeTransitions.slideRightToLeft(ProfileScreen());
          case '/checkin':
            return FitLifeTransitions.slideRightToLeft(CheckInScreen());
          case '/checkin-history':
            return FitLifeTransitions.fadeScale(CheckInHistoryScreen());
          default:
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            );
        }
      },
    );
  }
}