import 'package:flutter/material.dart';

import 'haptics.dart';
import 'timer_engine.dart';

void showSettingsSheet(BuildContext context, PomodoroEngine engine) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      // Rebuild on every engine change via a ListenableBuilder.
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ListenableBuilder(
          listenable: engine,
          builder: (context, _) {
            final s = engine.settings;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _DurationTile(
                  title: 'Focus length',
                  minutes: s.workMinutes,
                  min: 5,
                  max: 90,
                  onChange: (v) => engine.updateSettings(v, null, null, null, null, null, null),
                ),
                _DurationTile(
                  title: 'Short break',
                  minutes: s.shortBreakMinutes,
                  min: 1,
                  max: 30,
                  onChange: (v) => engine.updateSettings(null, v, null, null, null, null, null),
                ),
                _DurationTile(
                  title: 'Long break',
                  minutes: s.longBreakMinutes,
                  min: 5,
                  max: 60,
                  onChange: (v) => engine.updateSettings(null, null, v, null, null, null, null),
                ),
                _DurationTile(
                  title: 'Focus sessions per long break',
                  minutes: s.sessionsPerLongBreak,
                  min: 2,
                  max: 8,
                  unit: '',
                  onChange: (v) => engine.updateSettings(null, null, null, v, null, null, null),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-start next session'),
                  value: s.autoStart,
                  onChanged: (v) =>
                      engine.updateSettings(null, null, null, null, v, null, null),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('3-second haptic ramp'),
                  subtitle: const Text('Escalating ticks before a session starts'),
                  value: s.hapticRamp,
                  onChanged: (v) =>
                      engine.updateSettings(null, null, null, null, null, v, null),
                ),
                const SizedBox(height: 4),
                Text('Vibration intensity',
                    style: Theme.of(context).textTheme.labelLarge),
                SegmentedButton<HapticIntensity>(
                  segments: const [
                    ButtonSegment(value: HapticIntensity.low, label: Text('Low')),
                    ButtonSegment(value: HapticIntensity.medium, label: Text('Med')),
                    ButtonSegment(value: HapticIntensity.high, label: Text('High')),
                  ],
                  selected: {s.intensity},
                  onSelectionChanged: (sel) => engine
                      .updateSettings(null, null, null, null, null, null, sel.first),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      switch (s.intensity) {
                        case HapticIntensity.low:
                          engine.haptics.breakStart(s.intensity);
                        case HapticIntensity.medium:
                          engine.haptics.workStart(s.intensity);
                        case HapticIntensity.high:
                          engine.haptics.sessionEnd(s.intensity);
                      }
                    },
                    icon: const Icon(Icons.vibration),
                    label: const Text('Preview vibration pattern'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.title,
    required this.minutes,
    required this.min,
    required this.max,
    required this.onChange,
    this.unit = 'min',
  });

  final String title;
  final int minutes;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: $minutes${unit.isEmpty ? '' : ' $unit'}',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: minutes.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$minutes $unit',
          onChanged: (v) => onChange(v.round()),
        ),
      ],
    );
  }
}
