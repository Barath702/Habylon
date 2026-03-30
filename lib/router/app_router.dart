import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/main_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/add_edit_habit_screen.dart';
import '../models/habit.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/add-habit',
        name: 'add-habit',
        builder: (context, state) {
          final habit = state.extra as Habit?;
          return AddEditHabitScreen(habit: habit);
        },
      ),
    ],
  );
});
