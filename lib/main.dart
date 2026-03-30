import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'models/completion.dart';
import 'models/task.dart';
import 'providers/settings_providers.dart';
import 'router/app_router.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitTypeAdapter());
  Hive.registerAdapter(FrequencyAdapter());
  Hive.registerAdapter(CompletionAdapter());
  Hive.registerAdapter(TaskAdapter());

  // Open boxes
  await Hive.openBox<Habit>('habits');
  await Hive.openBox<Completion>('completions');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox(settingsBoxName);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0e0e0e),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: PulseHabitApp(),
    ),
  );
}

class PulseHabitApp extends ConsumerWidget {
  const PulseHabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeColor = ref.watch(themeColorProvider);

    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(themeColor.color),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: primaryColor,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        onBackground: AppColors.onBackground,
        onSurface: AppColors.onSurface,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onError: AppColors.onError,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceBright: AppColors.surfaceBright,
        surfaceDim: AppColors.surfaceDim,
      ),
      fontFamily: 'Manrope',
      textTheme: TextTheme(
        displayLarge: AppTypography.headlineLarge,
        displayMedium: AppTypography.headlineMedium,
        displaySmall: AppTypography.headlineSmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: primaryColor.withOpacity(0.15),
        labelStyle: AppTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          side: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface.withOpacity(0.8),
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.onSurfaceVariant,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.onSurface,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(
            color: primaryColor.withOpacity(0.5),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}
