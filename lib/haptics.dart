import 'dart:async';

import 'package:flutter/services.dart';

enum HapticIntensity { low, medium, high }

enum HapticLevel { light, medium, heavy, vibrate }

typedef VibeStep = (Duration delay, HapticLevel level);

/// Plays small vibration/haptic sequences built from framework-level
/// [HapticFeedback] calls so no custom platform channels are required.
class HapticEngine {
  HapticEngine();

  int _run = 0;

  void cancel() => _run++;

  void pulse(HapticLevel level) {
    switch (level) {
      case HapticLevel.light:
        HapticFeedback.lightImpact();
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
      case HapticLevel.heavy:
        HapticFeedback.heavyImpact();
      case HapticLevel.vibrate:
        HapticFeedback.vibrate();
    }
  }

  /// Plays [steps] in order; a newer play or [cancel] stops the sequence.
  Future<void> play(List<VibeStep> steps) async {
    final run = ++_run;
    for (final (delay, level) in steps) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (run != _run) return;
      pulse(level);
    }
  }

  /// Distinct signature for the start of a work session.
  Future<void> workStart(HapticIntensity intensity) => play(switch (intensity) {
        HapticIntensity.low => const [
            (Duration(milliseconds: 120), HapticLevel.medium),
            (Duration(milliseconds: 150), HapticLevel.medium),
          ],
        HapticIntensity.medium => const [
            (Duration(milliseconds: 120), HapticLevel.heavy),
            (Duration(milliseconds: 180), HapticLevel.heavy),
          ],
        HapticIntensity.high => const [
            (Duration(milliseconds: 100), HapticLevel.vibrate),
            (Duration(milliseconds: 150), HapticLevel.heavy),
            (Duration(milliseconds: 150), HapticLevel.heavy),
          ],
      });

  /// Distinct signature for the start of a break.
  Future<void> breakStart(HapticIntensity intensity) => play(switch (intensity) {
        HapticIntensity.low => const [
            (Duration(milliseconds: 100), HapticLevel.light),
            (Duration(milliseconds: 100), HapticLevel.light),
          ],
        HapticIntensity.medium => const [
            (Duration(milliseconds: 100), HapticLevel.light),
            (Duration(milliseconds: 120), HapticLevel.medium),
          ],
        HapticIntensity.high => const [
            (Duration(milliseconds: 90), HapticLevel.medium),
            (Duration(milliseconds: 120), HapticLevel.medium),
            (Duration(milliseconds: 120), HapticLevel.light),
          ],
      });

  /// Strong signature once the timer reaches zero.
  Future<void> sessionEnd(HapticIntensity intensity) => play(switch (intensity) {
        HapticIntensity.low => const [
            (Duration(milliseconds: 0), HapticLevel.medium),
            (Duration(milliseconds: 250), HapticLevel.medium),
          ],
        HapticIntensity.medium => const [
            (Duration(milliseconds: 0), HapticLevel.heavy),
            (Duration(milliseconds: 200), HapticLevel.heavy),
            (Duration(milliseconds: 200), HapticLevel.vibrate),
          ],
        HapticIntensity.high => const [
            (Duration(milliseconds: 0), HapticLevel.vibrate),
            (Duration(milliseconds: 180), HapticLevel.vibrate),
            (Duration(milliseconds: 180), HapticLevel.heavy),
            (Duration(milliseconds: 180), HapticLevel.heavy),
          ],
      });

  /// One tick of the 3-second arming ramp. Escalates as t approaches zero
  /// (t is whole seconds remaining: 3, 2, 1).
  void rampTick(int t, HapticIntensity intensity) {
    final base = switch (intensity) {
      HapticIntensity.low => HapticLevel.light,
      HapticIntensity.medium => HapticLevel.medium,
      HapticIntensity.high => HapticLevel.heavy,
    };
    final level = switch (t) {
      3 => HapticLevel.light,
      2 => base,
      _ => switch (base) {
          HapticLevel.light => HapticLevel.medium,
          HapticLevel.medium => HapticLevel.heavy,
          _ => HapticLevel.vibrate,
        },
    };
    pulse(level);
  }
}
