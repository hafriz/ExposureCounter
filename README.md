# Exposure and Response Prevention Companion

A private, offline-first application for recording daily check-ins, preparing exposure practices, tracking response prevention efforts, and reviewing personal records. It is a self-monitoring tool, not a therapist or a source of medical advice.

The application does not diagnose obsessive-compulsive disorder or anxiety disorders, interpret records clinically, or provide reassurance about feared outcomes. Treatment decisions belong with an appropriately qualified healthcare professional. This is not an emergency service.

## Application philosophy

- Record only what is useful; check-ins and exposure measurements are optional.
- Success is not defined by anxiety reaching zero.
- A response prevention attempt can be meaningful even when distress remains high.
- Progress summaries describe recorded activity and do not claim treatment effectiveness.
- Information stays on the device unless the user explicitly exports it.

## Technology and architecture

- Flutter and Dart with Material 3 and system light/dark themes
- Riverpod providers for UI data and refreshable state
- GoRouter for app navigation
- SQLite through `sqflite` for local persistence
- `fl_chart` for a simple recorded-anxiety chart
- `intl`, `uuid`, `path_provider`, and `share_plus`

The database currently uses SQLite directly through `sqflite`; Drift code generation and migrations have not yet been added. All repository access is kept outside presentation widgets. There is no backend, account, analytics, advertising, or network sync.

### Folder structure

```text
lib/
  core/                 Theme, providers, and reusable controls
  data/                 Local SQLite repository
  features/
    check_in/           Daily check-in model and screen
    dashboard/          Dashboard
    exposure/           Hierarchy, sessions, and measurements
    history/            Local history and user-initiated CSV export
    insights/           Deterministic recorded-data summaries
    urges/              Compulsion urges and response delays
  app.dart              Routes and application shell
  main.dart             Application entry point
test/
  features/             Unit tests for deterministic insight calculations
```

### Local database

The version-one database creates indexed tables for daily check-ins, exposure hierarchy items, exposure sessions, exposure measurements, compulsion urges, and response delays. Foreign keys cascade session measurement deletion and preserve associated records safely when hierarchy items are removed. A session's start timestamp is persisted; elapsed time is derived from that timestamp, allowing an unfinished session to be resumed after the application restarts.

## Current functionality

- Dashboard with a one-tap check-in and a resumable active exposure
- Daily check-ins with 0–10 anxiety and compulsion-urge ratings, mood, optional trigger, and note
- Custom exposure hierarchy with difficulty ordering, manual reordering, and status selection
- Exposure start ratings, optional in-session measurements, elapsed-time display, and neutral session completion
- Compulsion-urge recording and 5-, 10-, or 20-minute response delays that recover from an application restart
- History for check-ins, sessions, and urges, including individual record deletion
- Deterministic averages, completed-session totals, prevented-response counts, and a check-in anxiety chart
- CSV export initiated by the user through the system share sheet
- Settings and privacy screen with support and safety information and delete-all data

## Known limitations

This is an initial functional foundation, not a complete production release. The current version does not yet include Drift, biometric application locking, configurable local reminders, weekly reflections, custom date-range filters, editing existing check-ins or hierarchy entries, response-delay outcome analytics, or a full settings interface. Android platform build files must be generated with Flutter before building this checkout.

## Development setup

Install the Flutter stable SDK and Android Studio or Android SDK tooling. From the project root:

```sh
flutter create . --platforms android
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

The `flutter create` step supplies the Android host project that is not present in this repository yet. For a release Android package, configure the Android signing credentials locally and run:

```sh
flutter build apk --release
```

Do not commit signing keys or credentials.

## Privacy and security

Application records are stored in the app's local SQLite database. CSV export writes a temporary file and opens the platform share sheet only after the user requests it. No records are sent to a service by this application. Device-level security should be enabled for sensitive personal data.

The current version does not implement application-level biometric locking or secure-storage configuration. Do not treat this initial implementation as a security-reviewed production release.

## Future work

Priorities include Drift-backed migrations, biometric lock and secure settings, reminders, weekly reflection, record editing, expanded insights, and accessibility verification. Any future synchronization must be optional, encrypted, and initiated with explicit user consent. Clinical interpretation and automated reassurance are out of scope.
