# Android / iOS setup

Android is included with application ID `com.afghaninusa` and label `Afghan In USA`.

iOS requires macOS + Xcode. Run `flutter create --platforms=ios .`, then `flutter pub get` and `dart run flutter_launcher_icons`.

Google Sign-In is already wired in Dart through `google_sign_in`. Real OAuth credentials, SHA-1/SHA-256 fingerprints, and any `GoogleService-Info.plist`/`google-services.json` must come from the owner's Google/Firebase project; none are invented or bundled.
