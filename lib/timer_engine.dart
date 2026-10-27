import 'dart:async';

import 'package:flutter/foundation.dart';

import 'haptics.dart';

enum SessionType { work, shortBreak, longBreak }

extension SessionTypeX on SessionType {
  String get label => switch (this) {
        SessionType.work => 'Focus',
        SessionType.shortBreak => 'Short break',
        SessionType.longBreak => 'Long break',
      };
}

enum TimerPhase { idle, arming, running, paused, finished }

class PomodoroSettings {
  PomodoroSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsPerLongBreak = 4,
    this.autoStart = true,
    this.hapticRamp = true,
    this.intensity = HapticIntensity.medium,
  });

  int workMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  int sessionsPerLongBreak;
  bool autoStart;
  bool hapticRamp;
  HapticIntensity intensity;

  Duration durationFor(SessionType type) => switch (type) {
        SessionType.work => Duration(minutes: workMinutes),
        SessionType.shortBreak => Duration(minutes: shortBreakMinutes),
        SessionType.longBreak => Duration(minutes: longBreakMinutes),
      };
}

class PomodoroEngine extends ChangeNotifier {
  PomodoroEngine({PomodoroSettings? settings, HapticEngine? haptics})
      : settings = settings ?? PomodoroSettings(),
        haptics = haptics ?? HapticEngine() {
    session = SessionType.work;
    total = this.settings.durationFor(session).inSeconds;
    remaining = total;
  }

  final HapticEngine haptics;

  PomodoroSettings settings;

  SessionType session = SessionType.work;
  TimerPhase phase = TimerPhase.idle;
  int total = 25 * 60;
  int remaining = 25 * 60;
  int armingSeconds = 0;
  int completedWorkSessions = 0;

  Timer? _ticker;

  bool get isRunning => phase == TimerPhase.running || phase == TimerPhase.arming;

  @override
  void dispose() {
    _stopTicker();
    haptics.cancel();
    super.dispose();
  }

  void start() {
    if (phase == TimerPhase.running || phase == TimerPhase.arming) return;
    _arm();
  }

  void pause() {
    if (phase != TimerPhase.running && phase != TimerPhase.arming) return;
    haptics.cancel();
    _stopTicker();
    phase = TimerPhase.paused;
    notifyListeners();
  }

  void reset() {
    haptics.cancel();
    _stopTicker();
    phase = TimerPhase.idle;
    total = settings.durationFor(session).inSeconds;
    remaining = total;
    notifyListeners();
  }

  /// Abandons the current session and moves to the next one.
  void skip() {
    haptics.cancel();
    _stopTicker();
    if (session == SessionType.work) {
      completedWorkSessions++;
    }
    _advanceToNext(autostart: false);
    notifyListeners();
  }

  void _arm() {
    // Fresh selection if the previous session finished while auto-start was off.
    if (phase == TimerPhase.finished) {
      _advanceToNext(autostart: false);
    }
    if (remaining <= 0) {
      remaining = total = settings.durationFor(session).inSeconds;
    }
    if (settings.hapticRamp) {
      phase = TimerPhase.arming;
      armingSeconds = 3;
      haptics.rampTick(armingSeconds, settings.intensity);
      _startTicker();
    } else {
      _beginRunning();
    }
    notifyListeners();
  }

  void _beginRunning() {
    phase = TimerPhase.running;
    unawaited(
      session == SessionType.work
          ? haptics.workStart(settings.intensity)
          : haptics.breakStart(settings.intensity),
    );
    _startTicker();
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    if (phase == TimerPhase.arming) {
      armingSeconds--;
      if (armingSeconds <= 0) {
        _beginRunning();
      } else {
        haptics.rampTick(armingSeconds, settings.intensity);
      }
      notifyListeners();
      return;
    }
    if (phase != TimerPhase.running) return;
    remaining--;
    if (remaining <= 0) {
      remaining = 0;
      _onSessionComplete();
    }
    notifyListeners();
  }

  void _onSessionComplete() {
    _stopTicker();
    phase = TimerPhase.finished;
    unawaited(haptics.sessionEnd(settings.intensity));
    if (session == SessionType.work) {
      completedWorkSessions++;
    }
    if (settings.autoStart) {
      _advanceToNext(autostart: true);
    }
  }

  /// Decides the next session and (optionally) arms it right away.
  void _advanceToNext({required bool autostart}) {
    if (session == SessionType.work) {
      session = (completedWorkSessions % settings.sessionsPerLongBreak == 0)
          ? SessionType.longBreak
          : SessionType.shortBreak;
    } else {
      session = SessionType.work;
    }
    total = settings.durationFor(session).inSeconds;
    remaining = total;
    if (autostart) {
      _arm();
    } else {
      notifyListeners();
    }
  }

  void updateSettings(
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsPerLongBreak,
    bool? autoStart,
    bool? hapticRamp,
    HapticIntensity? intensity,
  ) {
    if (workMinutes != null) settings.workMinutes = workMinutes.clamp(1, 90);
    if (shortBreakMinutes != null) {
      settings.shortBreakMinutes = shortBreakMinutes.clamp(1, 30);
    }
    if (longBreakMinutes != null) {
      settings.longBreakMinutes = longBreakMinutes.clamp(1, 60);
    }
    if (sessionsPerLongBreak != null) {
      settings.sessionsPerLongBreak = sessionsPerLongBreak.clamp(2, 8);
    }
    if (autoStart != null) settings.autoStart = autoStart;
    if (hapticRamp != null) settings.hapticRamp = hapticRamp;
    if (intensity != null) settings.intensity = intensity;

    if (!isRunning) {
      total = settings.durationFor(session).inSeconds;
      remaining = total;
    }
    notifyListeners();
  }
}
