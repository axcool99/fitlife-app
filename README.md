# Momentum - Fitness Tracking App

Find Your Flow - A comprehensive Flutter fitness tracking application with Firebase backend integration.

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Firebase project with Firestore and Authentication enabled
- Android Studio or VS Code with Flutter extensions

### Firebase Configuration

**Important:** The `lib/firebase_options.dart` file is not included in this repository for security reasons as it contains sensitive Firebase API keys.

#### For New Developers:
1. Clone the repository
2. Set up your Firebase project at [Firebase Console](https://console.firebase.google.com/)
3. Configure FlutterFire:
   ```bash
   flutter pub add firebase_core
   flutterfire configure
   ```
   This will generate the `lib/firebase_options.dart` file automatically.

#### Alternative Setup:
If you have an existing Firebase project, you can manually create the `lib/firebase_options.dart` file by copying the configuration from your Firebase project settings.

### Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Features

- User authentication with Firebase Auth
- Daily fitness check-ins and weight tracking
- Workout logging and tracking
- Progress analytics with charts
- Profile management

## Project Structure

```
lib/
├── main.dart              # App entry point
├── auth_wrapper.dart      # Authentication state management
├── main_scaffold.dart     # Bottom navigation scaffold
├── home_screen.dart       # Main dashboard
├── workout_screen.dart    # Workout tracking
├── checkin_screen.dart    # Daily check-ins
├── progress_screen.dart   # Analytics and progress
├── profile_screen.dart    # User profile
├── models/                # Data models
├── services/              # Firebase services
└── ui/                   # UI components and theme
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Security

- Firebase configuration files are excluded from version control
- Never commit API keys or sensitive credentials
- Use environment variables for sensitive configuration in production
