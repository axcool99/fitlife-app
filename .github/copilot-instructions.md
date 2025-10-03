# FitLife Flutter App - AI Agent Instructions

## Architecture Overview

**FitLife** is a Flutter fitness tracking app with Firebase backend. Key architectural patterns:

- **Authentication Flow**: `AuthWrapper` listens to Firebase Auth state changes, routing authenticated users to `HomeScreen` and unauthenticated to `LoginScreen`
- **Service Layer**: Dedicated services in `lib/services/` handle Firebase Firestore operations (ProfileService, FitnessDataService, CheckInService, WorkoutService, AnalyticsService)
- **Data Models**: Located in `lib/models/` with Firestore serialization methods (`fromFirestore()`, `toFirestore()`)
- **UI Components**: Custom design system in `lib/ui/` with monochromatic dark theme, reusable components, and smooth transitions

## Key Patterns & Conventions

### Firebase Integration
- **User-scoped data**: All collections are nested under user documents (`users/{userId}/profile/data`, `users/{userId}/fitnessData`, etc.)
- **Real-time streams**: Services provide Stream methods for reactive UI updates (e.g., `ProfileService.getProfileStream()`)
- **Error handling**: Services use try-catch with print statements for debugging, returning null on failures

### State Management
- **Service injection**: Screens instantiate services directly in State objects (e.g., `_fitnessDataService = FitnessDataService()`)
- **StreamBuilder pattern**: Used extensively for reactive UI updates from Firebase streams

### UI/UX Patterns
- **Custom theme**: `FitLifeTheme` defines colors, typography (Poppins font), and maintains backward compatibility
- **Component library**: Reusable widgets in `lib/ui/components/` with consistent styling and animations
- **Route transitions**: Custom transitions defined in `FitLifeTransitions` for different screen types

### Code Syntax Patterns
- **List initialization**: Use `List<Type> variable = [];` instead of `final variable = <Type>();` to avoid parser issues
- **Firebase error handling**: Services return `null` on failures with `print('Error: $e')` for debugging

## Development Workflows

### Building & Running
- **Standard Flutter commands**: `flutter run`, `flutter build apk/ios`
- **Firebase configuration**: Requires `google-services.json` in `android/app/` and Firebase project setup
- **Asset management**: Logos stored in root directory, referenced in `pubspec.yaml`

### Testing
- **Unit tests**: Located in `test/` directory, run with `flutter test`
- **Integration**: Firebase services require emulator setup for testing

### Code Organization
- **Screen files**: Main UI screens in `lib/` root (home_screen.dart, workout_screen.dart, etc.)
- **Import pattern**: Relative imports within lib/, absolute paths for external packages
- **Export barrel files**: `services.dart`, `models.dart`, `components.dart` centralize exports

## Common Tasks

### Adding New Features
1. Create service class in `lib/services/` following existing patterns
2. Add data model in `lib/models/` with Firestore serialization
3. Create screen file in `lib/` root
4. Add route in `main.dart` with appropriate transition
5. Update navigation in relevant screens

### Firebase Operations
- **Document creation**: Use service methods that handle user scoping automatically
- **Real-time updates**: Prefer Stream methods over one-time reads for dynamic data
- **Data validation**: Implement in model constructors and service methods

### UI Development
- **Theme usage**: Always use `FitLifeTheme` colors and text styles
- **Component reuse**: Check `lib/ui/components/` before creating new widgets
- **Responsive design**: Use MediaQuery and LayoutBuilder for adaptive layouts

## File Structure Reference
```
lib/
├── main.dart              # App entry point, routing, theme setup
├── auth_wrapper.dart      # Firebase auth state management
├── *_screen.dart          # Main UI screens
├── models/                # Data models with Firestore integration
├── services/              # Business logic and Firebase operations
└── ui/                    # Design system and reusable components
```</content>
<parameter name="filePath">/Users/axcool/Desktop/ff/.github/copilot-instructions.md