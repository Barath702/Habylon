# Pulse Habit Tracker

A high-end offline habit tracking Flutter app with a neon-glass editorial design system.

## Screenshots

<table>
  <tr>
    <td><img src="Screenshots/1.png" width="250"/></td>
    <td><img src="Screenshots/2.png" width="250"/></td>
    <td><img src="Screenshots/3.png" width="250"/></td>
  </tr>
  <tr>
    <td><img src="Screenshots/4.png" width="250"/></td>
    <td><img src="Screenshots/5.png" width="250"/></td>
    <td><img src="Screenshots/6.png" width="250"/></td>
  </tr>
</table>

## Design System

Based on the "Luminescent Pulse" creative direction, this app features:
- **Pure black background** (#0e0e0e) for maximum neon vibrance
- **Glassmorphism** effects with blur and transparency
- **Neon accent colors**: Purple (#bc9eff), Green (#52fd98), Orange (#ffb37f)
- **No hard borders** - using tonal depth and luminescent shadows instead
- **Typography**: Manrope (headlines/body) + Space Grotesk (labels)

## Features

### 1. Home Dashboard
- Habit cards with heatmap grids showing past 8 days
- Check/uncheck habits with animated feedback
- Category filter chips (All, Fitness, Health, Morning, Nutrition)
- Weekly summary bento boxes (Consistency + Streak stats)
- Floating FAB for adding new habits

### 2. Tasks Timeline
- Vertical timeline grouped by date
- Categories: Personal (orange), Work (purple), Health (green)
- Toggle completed tasks
- "All done!" celebration card
- Add new tasks modal

### 3. Time Tracking
- Weekly day indicators (MON-SUN)
- Time grid showing hours per day/week
- Activity density bar chart
- Progress bars for daily targets

### 4. Calendar
- Monthly calendar grid with completion highlights
- Streak display for selected habit
- Completion percentage and total days stats
- Weekly insights card

### 5. Add/Edit Habit
- Icon picker with 8+ options
- Color theme selector (5 neon colors)
- Habit type toggle (Checkmark vs Time Tracked)
- Frequency selector (Daily/Weekly)
- Days per week counter for weekly habits

## Technical Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Local Database | Hive |
| Animations | flutter_animate |
| Fonts | Google Fonts (Manrope, Space Grotesk) |

## Architecture

```
lib/
├── main.dart                    # App entry point with theme
├── models/
│   ├── habit.dart              # Habit model with Hive
│   ├── completion.dart         # Daily completion tracking
│   └── task.dart               # Task model
├── providers/
│   └── database_providers.dart # Riverpod + Hive setup
├── router/
│   └── app_router.dart         # GoRouter configuration
├── screens/
│   ├── home_screen.dart
│   ├── tasks_screen.dart
│   ├── time_tracking_screen.dart
│   ├── calendar_screen.dart
│   └── add_edit_habit_screen.dart
├── widgets/
│   ├── glass_widgets.dart     # GlassContainer, GlowContainer, NeonButton
│   ├── heatmap_widgets.dart   # HeatmapGrid, WeekHeatmap, CalendarDay
│   └── bottom_nav.dart        # Custom bottom navigation
└── utils/
    └── theme.dart             # Colors, Typography, Spacing
```

## Getting Started

### Prerequisites
- Flutter SDK >=3.0.0
- Android Studio / Xcode for emulators

### Installation

1. Clone the repository:
```bash
cd /home/barath/Habit
```

2. Get dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters (if needed):
```bash
flutter packages pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

## Data Models

### Habit
```dart
- id: String (UUID)
- name: String
- color: String (primary/secondary/tertiary/error/errorContainer)
- icon: String (material icon name)
- type: HabitType (check/time)
- streak: int
- frequency: Frequency (daily/weekly)
- targetDaysPerWeek: int?
- targetTime: double? (hours)
```

### Completion
```dart
- habitId: String
- date: DateTime
- completed: bool
- timeValue: double? (for time-tracked)
- count: int? (for countable habits)
```

### Task
```dart
- id: String (UUID)
- title: String
- category: String (Personal/Work/Health)
- date: DateTime
- completed: bool
- priority: int?
```

## Design Tokens

### Colors
- Background: #0e0e0e
- Surface variants: #1a1919, #131313, #262626
- Primary (Neon Purple): #bc9eff
- Secondary (Neon Green): #52fd98
- Tertiary (Neon Orange): #ffb37f

### Typography
- Headlines: Manrope (800/700/600)
- Body: Manrope (500/400)
- Labels: Space Grotesk (700/500)

### Spacing
- xs: 4dp
- sm: 8dp
- md: 12dp
- lg: 16dp
- xl: 20dp
- xxl: 24dp

### Radii
- lg: 16dp
- xl: 24dp
- full: 9999px (pill shape)

## Offline First

This app is designed to work 100% offline:
- No internet permissions required
- All data stored locally via Hive
- No Firebase, Supabase, or cloud services
- Zero authentication needed

## Animations

- Habit check: Scale pulse + glow effect
- Button press: Shrink animation
- Screen transitions: Fade + slide
- Bottom nav: Active indicator animation
- FAB: Rotation on long press

## License

MIT License - Free for personal and commercial use.
