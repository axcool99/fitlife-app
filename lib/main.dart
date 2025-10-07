import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'services/health_service.dart'; // Import health service
import 'services/wearable_sync_service.dart'; // Import wearable sync service
import 'services/exercise_service.dart'; // Import exercise service
import 'device_connection_screen.dart'; // Import device connection screen
import 'nutrition_screen.dart'; // Import nutrition screen

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup all dependencies for the app
Future<void> setupDependencies() async {
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Failed to load .env file: $e');
    // Continue with app startup - API keys might be handled differently in production
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register CacheService as a singleton
  final cacheService = CacheService();
  try {
    await cacheService.init();
  } catch (e) {
    print('Warning: Failed to initialize cache service: $e');
    // Continue without cache - app can still function
  }
  getIt.registerSingleton<CacheService>(cacheService);

  // Register NetworkService
  final networkService = NetworkService();
  getIt.registerSingleton<NetworkService>(networkService);

  // Initialize health services
  final healthService = HealthService();
  final wearableSyncService = WearableSyncService(healthService, cacheService, networkService);

  getIt.registerSingleton<HealthService>(healthService);
  getIt.registerSingleton<WearableSyncService>(wearableSyncService);
  getIt.registerSingleton<FitnessDataService>(FitnessDataService(wearableSyncService));

  // Register other services
  getIt.registerLazySingleton<WorkoutService>(
    () => WorkoutService(getIt<CacheService>(), getIt<FitnessDataService>()),
  );
  getIt.registerLazySingleton<CheckInService>(
    () => CheckInService(getIt<CacheService>()),
  );
  getIt.registerLazySingleton<ProfileService>(() => ProfileService());
  getIt.registerLazySingleton<UserPreferencesService>(
    () => UserPreferencesService(getIt<CacheService>()),
  );
  getIt.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(getIt<CacheService>(), getIt<NetworkService>()),
  );
  getIt.registerLazySingleton<AIService>(
    () => AIService(
      getIt<AnalyticsService>(),
      getIt<ProfileService>(),
      getIt<UserPreferencesService>(),
    ),
  );
  getIt.registerLazySingleton<GamificationService>(
    () => GamificationService(getIt<AnalyticsService>()),
  );
  getIt.registerLazySingleton<NutritionService>(
    () => NutritionService(getIt<CacheService>(), getIt<NetworkService>()),
  );

  // Register ExerciseService with dependencies
  getIt.registerLazySingleton<ExerciseService>(
    () => ExerciseService(
      cacheService: getIt<CacheService>(),
      networkService: getIt<NetworkService>(),
    ),
  );

  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      getIt<CacheService>(),
      getIt<WorkoutService>(),
      getIt<CheckInService>(),
    ),
  );

  // Request health permissions after services are initialized
  try {
    await healthService.requestPermissions();
  } catch (e) {
    print('Failed to request health permissions: $e');
  }

  // Start background sync for wearable data
  try {
    wearableSyncService.startBackgroundSync();
  } catch (e) {
    print('Failed to start background sync: $e');
  }
}

/// Reset all dependencies (useful for logout or profile switching)
Future<void> resetDependencies() async {
  // Clear existing registrations
  await getIt.reset();

  // Re-setup dependencies
  await setupDependencies();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup all dependencies
  await setupDependencies();

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
        '/device-connection': (context) => const DeviceConnectionScreen(),
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
          case '/device-connection':
            return FitLifeTransitions.slideRightToLeft(DeviceConnectionScreen());
          default:
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            );
        }
      },
    );
  }
}