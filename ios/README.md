# iOS

The Dart/Flutter project is iOS-ready. Because iOS Runner/Xcode project generation requires macOS/Xcode, the complete Runner project must be generated on a Mac with the current stable Flutter SDK:

    flutter create --platforms=ios .
    flutter pub get
    dart run flutter_launcher_icons

Then open `ios/Runner.xcworkspace` and use bundle identifier `com.afghaninusa`.
