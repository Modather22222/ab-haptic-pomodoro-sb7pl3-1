import 'package:flutter/material.dart';

import 'main.dart';
import 'settings_sheet.dart';
import 'timer_engine.dart';

String _fmt(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = ChangeNotifierProvider.of<PomodoroEngine>(context);
    final scheme = Theme.of(context).colorScheme;

    final color = switch (engine.session) {
      SessionType.work => scheme.primary,
      SessionType.shortBreak => scheme.tertiary,
      SessionType.longBreak => scheme.secondary,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haptic Pomodoro'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsSheet(context, engine),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SessionPips(engine: engine),
              const SizedBox(height: 16),
              Text(
                engine.phase == TimerPhase.finished
                    ? "Time's up - next: ${_nextLabel(engine)}"
                    : engine.session.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              _TimerDial(engine: engine, color: color),
              const SizedBox(height: 24),
              _Controls(engine: engine, color: color),
            ],
          ),
        ),
      ),
    );
  }

  String _nextLabel(PomodoroEngine engine) {
    if (engine.session == SessionType.work) {
      final next = (engine.completedWorkSessions % engine.settings.sessionsPerLongBreak == 0)
          ? SessionType.longBreak
          : SessionType.shortBreak;
      return next.label;
    }
    return SessionType.work.label;
  }
}

class _SessionPips extends StatelessWidget {
  const _SessionPips({required this.engine});

  final PomodoroEngine engine;

  @override
  Widget build(BuildContext context) {
    final done = engine.completedWorkSessions;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < engine.settings.sessionsPerLongBreak; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < done % engine.settings.sessionsPerLongBreak ||
                      (done > 0 && done % engine.settings.sessionsPerLongBreak == 0 && engine.session != SessionType.work)
                  ? Icons.circle
                  : Icons.circle_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({required this.engine, required this.color});

  final PomodoroEngine engine;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialSize = size.shortestSide * 0.55;
    final progress = engine.total > 0 ? 1 - engine.remaining / engine.total : 0.0;

    final centerText = engine.phase == TimerPhase.arming
        ? '${engine.armingSeconds}'
        : _fmt(engine.remaining);
    final subtext = engine.phase == TimerPhase.arming
        ? 'Get ready…'
        : engine.phase == TimerPhase.paused
            ? 'Paused'
            : '';

    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: dialSize,
            height: dialSize,
            child: CircularProgressIndicator(
              value: engine.phase == TimerPhase.idle ? 0 : progress.clamp(0.0, 1.0),
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtext.isNotEmpty)
                Text(
                  subtext,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.engine, required this.color});

  final PomodoroEngine engine;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final running = engine.isRunning;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.tonalIcon(
            onPressed: running ? engine.pause : engine.start,
            icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(running ? 'Pause' : 'Start'),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: 'Reset',
            onPressed: engine.reset,
            icon: const Icon(Icons.replay_rounded),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: 'Skip session',
            onPressed: engine.skip,
            icon: const Icon(Icons.skip_next_rounded),
          ),
        ],
      ),
    );
  }
}
