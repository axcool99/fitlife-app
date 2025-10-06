import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'checkin_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'ui/theme/theme.dart';

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

  // List of screens for IndexedStack (preserves state)
  final List<Widget> _screens = [
    const HomeScreen(),
    WorkoutScreen(key: WorkoutScreen.screenKey),
    const CheckInScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  // Bottom navigation items
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
      icon: Icon(Icons.show_chart_outlined),
      activeIcon: Icon(Icons.show_chart),
      label: 'Progress',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: FitLifeTheme.surfaceColor,
        selectedItemColor: FitLifeTheme.accentGreen,
        unselectedItemColor: FitLifeTheme.textSecondary,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: _navItems,
      ),
    );
  }
}