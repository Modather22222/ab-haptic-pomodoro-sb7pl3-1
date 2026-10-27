import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:haptic_pomodoro/main.dart';

void main() {
  testWidgets('app renders the timer dial with the default focus duration',
      (tester) async {
    await tester.pumpWidget(const HapticPomodoroApp());

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
