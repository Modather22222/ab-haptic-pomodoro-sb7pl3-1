import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'timer_engine.dart';

void main() => runApp(const HapticPomodoroApp());

class HapticPomodoroApp extends StatelessWidget {
  const HapticPomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFFB3261E));
    return ChangeNotifierProvider(
      create: () => PomodoroEngine(),
      child: MaterialApp(
        title: 'Haptic Pomodoro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB3261E),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}

/// Tiny [ChangeNotifier] scoper so the app can stay dependency-free.
class ChangeNotifierProvider extends InheritedNotifier<ChangeNotifier> {
  ChangeNotifierProvider({
    super.key,
    required ChangeNotifier Function() create,
    required super.child,
  }) : super(notifier: create());

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ChangeNotifierProvider>()
        ?.notifier;
    if (scope is! T) {
      throw StateError('No $T found above ${context.widget}');
    }
    return scope;
  }
}
