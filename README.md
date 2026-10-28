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

The version-two database has an upgrade path from version one and creates indexed tables for daily check-ins, exposure hierarchy items, exposure sessions, exposure measurements, compulsion urges, and response delays. Foreign keys cascade session measurement deletion and preserve associated records safely when hierarchy items are removed. A session's start timestamp is persisted; elapsed time is derived from that timestamp, allowing an unfinished session to be resumed after the application restarts.

## Current functionality

- Dashboard with a one-tap check-in and a resumable active exposure
- Daily check-ins with 0–10 anxiety and compulsion-urge ratings, mood, optional trigger, and note
- Custom exposure hierarchy with difficulty ordering, manual reordering, and status selection
- Exposure start ratings, optional in-session measurements, elapsed-time display, and neutral session completion
- Compulsion-urge recording and 5-, 10-, or 20-minute response delays that recover from an application restart
- History for check-ins, sessions, and urges, including individual record deletion
- Deterministic averages, completed-session totals, prevented-response counts, a check-in anxiety chart, and custom date-range filters on the Insights page
- CSV export initiated by the user through the system share sheet
- Settings and privacy screen with support and safety information and delete-all data

## Known limitations

This is an initial functional foundation, not a complete production release. The current version does not yet include Drift, biometric application locking, configurable local reminders, weekly reflections, editing existing check-ins or hierarchy entries, response-delay outcome analytics, or a full settings interface. Android platform build files must be generated with Flutter before building this checkout.

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

Priorities include Drift-backed migrations, biometric lock and secure settings, reminders, weekly reflection, record editing, expanded insights (including additional filterable metrics), and accessibility verification. Any future synchronization must be optional, encrypted, and initiated with explicit user consent. Clinical interpretation and automated reassurance are out of scope.

## CI/CD: Automatic Android APK builds

This repository includes a GitHub Actions workflow at `.github/workflows/build-android-apk.yml` to automatically build a release APK.

### Triggers
- **Manual dispatch** (`workflow_dispatch`): Run the workflow from GitHub Actions → "Build Android APK" → "Run workflow". 
- **Version tags** (`push` tags matching `v*`): Pushing a tag like `v1.0.0` will build the APK and create a GitHub Release with the APK attached as a downloadable asset.

### Flutter/SDK versions
- Flutter: `3.35.7` (stable, pinned in CI)
- Java: `17` (Temurin)
- Android builds use the default Flutter release signing configuration in CI. **No secrets/keystores are committed or required** for an unsigned-debug-equivalent release APK built without a custom `key.properties`; if you want to publish a properly signed release, configure `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` as repository secrets and update the workflow/`android/app/build.gradle` accordingly.

### Build behavior
1. Checks out the repo
2. Sets up Java 17 and Flutter 3.35.7 (cached)
3. Runs `flutter pub get`
4. If the `android/` directory is missing, runs `flutter create . --platforms android --project-name exposure_counter` **without overwriting existing app code** (it only generates when absent)
5. Runs `flutter build apk --release`
6. **Manual runs**: uploads `build/app/outputs/flutter-apk/app-release.apk` as a workflow artifact (downloadable from the workflow run page)
7. **Tag runs**: creates a GitHub Release for the tag and attaches the APK as a release asset

### Download / install instructions
- **From a tag release**: Go to Releases → select the tag (e.g., `v1.0.0`) → download `app-release.apk` under "Assets". 
- **From a manual workflow run**: Go to Actions → run → "Artifacts" section → download `exposure-counter-release-apk.zip` (contains `app-release.apk`).
- **Install on Android**: Transfer the APK to your device and install it. You may need to allow installation from unknown sources for that app/file. This app stores data locally and has no network sync; see Privacy & Security above.

### Limitations
- **Signing**: CI builds without custom signing credentials produce an APK signed with Flutter's default debug signing key in many setups or requires configuration; for distribution outside testing, configure proper release signing via secrets.
- **Android host project**: If `android/` already exists in the repo, the workflow does **not** regenerate/overwrite it. If it's missing (as noted in "Known limitations"), it will be generated safely.
- **Offline-first**: No backend/analytics/network features are added by this workflow.
