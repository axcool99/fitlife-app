import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'checkin_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'nutrition_screen.dart';
import 'ui/theme/theme.dart';
import 'ui/components/components.dart';

/// MainScaffold - Main app scaffold with bottom navigation
/// Manages navigation between the 5 main screens using IndexedStack
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  // Global key to access MainScaffold state from anywhere
  static final GlobalKey<_MainScaffoldState> scaffoldKey = GlobalKey<_MainScaffoldState>();

  // Static method to navigate to a specific tab
  static void navigateToTab(int index) {
    scaffoldKey.currentState?._navigateToTab(index);
  }

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // List of screens for IndexedStack (preserves state)
  final List<Widget> _screens = [
    HomeScreen(key: HomeScreen.screenKey),
    WorkoutScreen(key: WorkoutScreen.screenKey),
    const CheckInScreen(),
    const NutritionScreen(),
    ProgressScreen(key: ProgressScreen.screenKey),
  ];

  // Bottom navigation items (removed Profile)
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center_outlined),
      activeIcon: Icon(Icons.fitness_center),
      label: 'Workouts',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment_turned_in_outlined),
      activeIcon: Icon(Icons.assignment_turned_in),
      label: 'Check-ins',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_outlined),
      activeIcon: Icon(Icons.restaurant),
      label: 'Nutrition',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.show_chart_outlined),
      activeIcon: Icon(Icons.show_chart),
      label: 'Progress',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: FitLifeTheme.surfaceColor,
          selectedItemColor: FitLifeTheme.accentGreen,
          unselectedItemColor: FitLifeTheme.textSecondary,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          iconSize: 20, // Smaller icons
          selectedFontSize: 10, // Smaller selected text
          unselectedFontSize: 10, // Smaller unselected text
          items: _navItems,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_selectedIndex) {
      case 0: // Home
        final user = _auth.currentUser;
        final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
        return AppBar(
          backgroundColor: FitLifeTheme.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          title: AppText(
            'Welcome, $userName',
            type: AppTextType.headingSmall,
            color: FitLifeTheme.primaryText,
            useCleanStyle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: FitLifeTheme.accentGreen,
              onPressed: () => _navigateToProfile(context),
              tooltip: 'Profile',
            ),
          ],
          toolbarHeight: kToolbarHeight,
        );
      case 1: // Workouts
        return AppBar(
          backgroundColor: FitLifeTheme.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          title: const AppText(
            'Your Workouts',
            type: AppTextType.headingSmall,
            color: FitLifeTheme.primaryText,
            useCleanStyle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: FitLifeTheme.accentGreen,
              onPressed: () => _navigateToProfile(context),
              tooltip: 'Profile',
            ),
          ],
          toolbarHeight: kToolbarHeight,
        );
      case 2: // Check-ins
        return AppBar(
          backgroundColor: FitLifeTheme.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          title: const AppText(
            'Check-ins',
            type: AppTextType.headingSmall,
            color: FitLifeTheme.primaryText,
            useCleanStyle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: FitLifeTheme.accentGreen,
              onPressed: () => _navigateToProfile(context),
              tooltip: 'Profile',
            ),
          ],
          toolbarHeight: kToolbarHeight,
        );
      case 3: // Nutrition
        return AppBar(
          backgroundColor: FitLifeTheme.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          title: const AppText(
            'Nutrition',
            type: AppTextType.headingSmall,
            color: FitLifeTheme.primaryText,
            useCleanStyle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              color: FitLifeTheme.accentGreen,
              onPressed: () async {
                // Get the current selected date from nutrition screen
                // For now, use today's date as default
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 7)),
                );
                if (picked != null) {
                  // Navigate to nutrition tab and update date
                  // This is a simplified version - in a real app you'd want to communicate with the nutrition screen
                  MainScaffold.navigateToTab(3);
                }
              },
              tooltip: 'Select Date',
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: FitLifeTheme.accentGreen,
              onPressed: () => _navigateToProfile(context),
              tooltip: 'Profile',
            ),
          ],
          toolbarHeight: kToolbarHeight,
        );
      case 4: // Progress
        return AppBar(
          backgroundColor: FitLifeTheme.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          title: const AppText(
            'Progress',
            type: AppTextType.headingSmall,
            color: FitLifeTheme.primaryText,
            useCleanStyle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: FitLifeTheme.accentGreen,
              onPressed: () => _navigateToProfile(context),
              tooltip: 'Profile',
            ),
          ],
          toolbarHeight: kToolbarHeight,
        );
      default:
        return AppBar(
          backgroundColor: FitLifeTheme.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: FitLifeTheme.accentGreen,
              onPressed: () => _navigateToProfile(context),
              tooltip: 'Profile',
            ),
          ],
          toolbarHeight: kToolbarHeight,
        );
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }
}