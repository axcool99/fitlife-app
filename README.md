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

- **Find Your Flow** - Personalized fitness journey tracking
- User authentication with Firebase Auth
- Daily fitness check-ins and weight tracking
- Comprehensive workout logging and tracking
- Advanced progress analytics with interactive charts
- Nutrition tracking with meal planning
- Health data integration (steps, calories, heart rate)
- Profile management and goal setting
- Gamification and achievement system
- Offline support with data synchronization

## Project Structure

```
lib/
├── main.dart                    # App entry point & dependency injection
├── auth_wrapper.dart           # Authentication state management
├── main_scaffold.dart          # Bottom navigation scaffold
├── home_screen.dart            # Main dashboard with health metrics
├── workout_screen.dart         # Workout logging and history
├── nutrition_screen.dart       # Meal tracking and nutrition analytics
├── progress_screen.dart        # Analytics and progress charts
├── profile_screen.dart         # User profile and settings
├── checkin_screen.dart         # Daily health check-ins
├── device_connection_screen.dart # Wearable device integration
├── models/                     # Data models and entities
├── services/                   # Business logic and API services
│   ├── analytics_service.dart  # User analytics and insights
│   ├── health_service.dart     # HealthKit/Google Fit integration
│   ├── workout_service.dart    # Workout data management
│   ├── nutrition_service.dart  # Nutrition and meal planning
│   └── wearable_sync_service.dart # Device synchronization
└── ui/                        # UI components and theming
    ├── components/            # Reusable UI components
    ├── dialogs/              # Modal dialogs and forms
    └── theme/                # App theming and styling
landing-page/                  # Marketing website
├── index.html               # Landing page with device showcase
├── style.css                # Landing page styling
└── script.js                # Interactive elements
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Screenshots

### App Screenshots
- **Dashboard**: Health metrics overview with personalized insights
- **Nutrition Tracking**: Meal logging with macronutrient breakdown and trends
- **Workout Logging**: Exercise tracking with progress analytics
- **Progress Charts**: Interactive visualizations of fitness journey
- **Device Integration**: Wearable sync and health data monitoring

### Landing Page
- Modern marketing website showcasing app features
- Device mockups and user testimonials
- Download links for App Store and Google Play

## Technology Stack

- **Frontend**: Flutter (Dart) - Cross-platform mobile development
- **Backend**: Firebase (Firestore, Auth, Cloud Functions)
- **State Management**: Provider pattern with dependency injection
- **Health Integration**: HealthKit (iOS) and Google Fit (Android)
- **Charts**: FL Chart library for data visualization
- **Storage**: Hive for local caching, Firebase for cloud sync

## Security

- Firebase configuration files are excluded from version control
- Never commit API keys or sensitive credentials
- End-to-end encryption for user data
- Secure authentication with Firebase Auth
- Privacy-first approach to health data handling
