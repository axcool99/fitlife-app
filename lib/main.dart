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
import 'auth_wrapper.dart'; // Import the auth wrapper
import 'ui/theme/theme.dart'; // Import our custom theme
import 'ui/components/components.dart'; // Import components with transitions
import 'services/cache_service.dart'; // Import cache service
import 'services/sync_service.dart'; // Import sync service
import 'services/workout_service.dart'; // Import workout service
import 'services/checkin_service.dart'; // Import checkin service

/// Simple service locator for app-wide services
class ServiceLocator {
  static CacheService? _cacheService;
  static SyncService? _syncService;

  static void initialize(CacheService cacheService) {
    _cacheService = cacheService;
    _syncService = SyncService(
      cacheService,
      WorkoutService(),
      CheckInService(),
    );
  }

  static CacheService get cacheService {
    if (_cacheService == null) {
      throw Exception('CacheService not initialized');
    }
    return _cacheService!;
  }

  static SyncService get syncService {
    if (_syncService == null) {
      throw Exception('SyncService not initialized');
    }
    return _syncService!;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize cache service
  final cacheService = CacheService();
  await cacheService.initialize();
  ServiceLocator.initialize(cacheService);

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
          default:
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            );
        }
      },
    );
  }
}