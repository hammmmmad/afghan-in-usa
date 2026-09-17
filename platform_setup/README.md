# Android Studio setup

This archive contains the Flutter source code and assets. The original archive
intentionally does not include generated `android/` or `ios/` platform folders.
Generate the Android folder with the current stable Flutter SDK before the first
Android build.

## Requirements
- Current stable Flutter / Dart SDK
- Android Studio with Android SDK installed
- JDK 17 (the Flutter/Android Studio bundled JDK is fine)

## First Android run
From the project root:

```bash
flutter create --org com.sarfrazkhamoosh --project-name afghan_in_usa --platforms=android .
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter run
```

The application code is platform-independent. `flutter_launcher_icons` is already
configured to use `assets/images/app_icon.png`.

## Google Sign-In status
The project currently contains `google_sign_in` and its Dart authentication
wrapper. It does **not** contain Firebase Authentication, `google-services.json`,
or Android OAuth credentials. Do not invent credentials. Google Sign-In will need
the real Android OAuth/SHA configuration when it is connected to a project.

## Future Firebase architecture
News screens depend on `NewsRepository`, with the current local JSON implementation
provided by `ApiService`. A Firestore implementation can later be added behind the
same contract. Notification topic IDs are centralized in
`lib/models/notification_preferences.dart`; Firebase Cloud Messaging is not enabled
until real Firebase configuration is supplied.
