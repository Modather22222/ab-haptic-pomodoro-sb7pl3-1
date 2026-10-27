# Haptic Pomodoro

A Material 3 focus timer with Pomodoro work/break cycles, delivered with
distinct vibration patterns for each session transition and an escalating
3-second haptic countdown ramp before a session starts. Durations, sessions
per long break, auto-start, the haptic ramp, and vibration intensity are all
adjustable from the in-app settings sheet.

State is in-memory (ChangeNotifier) and haptics use Flutter's built-in
HapticFeedback API, so there are no third-party packages or platform code.

## Run

```sh
flutter pub get && flutter run
