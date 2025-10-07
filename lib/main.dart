import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
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
import 'services/network_service.dart'; // Import network service
import 'services/sync_service.dart'; // Import sync service
import 'services/workout_service.dart'; // Import workout service
import 'services/checkin_service.dart'; // Import checkin service
import 'services/fitness_data_service.dart'; // Import fitness data service
import 'services/profile_service.dart'; // Import profile service
import 'services/analytics_service.dart'; // Import analytics service
import 'services/user_preferences_service.dart'; // Import user preferences service
import 'services/ai_service.dart'; // Import AI service
import 'services/gamification_service.dart'; // Import gamification service
import 'services/nutrition_service.dart'; // Import nutrition service
import 'nutrition_screen.dart'; // Import nutrition screen

/// Global service locator instance
final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize and register services with dependency injection
  final networkService = NetworkService();
  final cacheService = CacheService(networkService);
  await cacheService.initialize();

  getIt.registerSingleton<NetworkService>(networkService);
  getIt.registerSingleton<CacheService>(cacheService);
  getIt.registerSingleton<FitnessDataService>(FitnessDataService());
  getIt.registerSingleton<WorkoutService>(WorkoutService(getIt<CacheService>()));
  getIt.registerSingleton<CheckInService>(CheckInService(getIt<CacheService>()));
  getIt.registerSingleton<ProfileService>(ProfileService());
  getIt.registerSingleton<UserPreferencesService>(UserPreferencesService(getIt<CacheService>()));
  getIt.registerSingleton<AnalyticsService>(AnalyticsService(getIt<CacheService>(), getIt<NetworkService>()));
  getIt.registerSingleton<AIService>(AIService(getIt<AnalyticsService>(), getIt<ProfileService>(), getIt<UserPreferencesService>()));
  getIt.registerSingleton<GamificationService>(GamificationService(getIt<AnalyticsService>()));
  getIt.registerSingleton<NutritionService>(NutritionService(getIt<CacheService>(), getIt<NetworkService>()));
  getIt.registerSingleton<SyncService>(SyncService(
    getIt<CacheService>(),
    getIt<WorkoutService>(),
    getIt<CheckInService>(),
  ));

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
        '/nutrition': (context) => const NutritionScreen(),
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
          case '/nutrition':
            return FitLifeTransitions.slideRightToLeft(NutritionScreen());
          default:
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            );
        }
      },
    );
  }
}