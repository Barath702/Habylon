import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/bottom_nav.dart';
import '../utils/theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  void _onNavTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFabTap() {
    // Navigate to add habit screen using go_router
    context.push('/add-habit');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        onFabTap: _onFabTap,
      ),
    );
  }
}
