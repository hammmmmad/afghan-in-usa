# Afghan in USA project update

## Completed in the source archive
- Inspected the complete archive structure before editing.
- Replaced the supplied application icon in `assets/images/app_icon.png` and `assets/images/app_logo.png`.
- Home header now renders the application logo as a circular avatar.
- Added explicit replaceable placeholders for creator profile and Published News artwork because separate creator/news photos were not included in the uploaded files.
- Moved all bundled legacy fonts under `assets/fonts/legacy/` and added the separately supplied fonts under `assets/fonts/`.
- Configured separate Persian news title/body, English, and Navigation Bar font families.
- Removed Pashto from localization, language selection, locale logic, and structured JSON data.
- Reworked news into a bilingual model with `titleFa/titleEn`, `summaryFa/summaryEn`, `contentFa/contentEn`, localized dates, category, image, publisher and source.
- Updated all seven bundled news articles with English title/summary/content.
- Made in-app notifications store both Persian and English text so language switching does not leave old notification text in the previous language.
- Centralized the supplied social links in `AppConfig.socials` and added URL normalization for the website value.
- Preserved Google Sign-In code; no Firebase credentials were invented. There is no Firebase Authentication configuration in the source archive.
- Added `NewsRepository` as a clean content abstraction for a future Firestore implementation.
- Added notification topic IDs for future Firebase Cloud Messaging without enabling Firebase.
- Fixed `CardTheme` -> `CardThemeData` in both light and dark themes for current Flutter APIs.
- Added/updated Android setup documentation and scripts.

## Verification performed in this environment
- JSON/ARB/YAML parsing: passed.
- Declared font-file existence: passed.
- Asset-path validation: passed.
- Seven bilingual news records: passed.
- Pashto text/key removal from source and structured content: passed.
- Supplied icon copied byte-for-byte to `app_icon.png`: passed.

## Not executable in this environment
The execution environment does not contain the Flutter/Dart SDK, so `flutter pub get`,
`flutter analyze`, and an Android Gradle build could not be run here. The archive also did
not contain a generated `android/` directory. Run `scripts/setup_platforms.ps1` on Windows
(or `scripts/setup_platforms.sh` on macOS/Linux) from the project root; it generates Android,
gets dependencies, generates launcher icons, and runs `flutter analyze`.

## Manual asset replacements later
Replace:
- `assets/images/creator_profile.png` with the real creator/developer photo.
- `assets/images/published_news.png` with the real Published News image.
- `assets/fonts/title.ttf` if a different Persian news-title font is desired.
- `assets/fonts/news.ttf` if a different Persian news-body font is desired.
- `assets/fonts/Magazine .otf` if a different English font is desired.
- `assets/fonts/navigation.otf` when the final Navigation Bar font is supplied.
- `assets/images/app_icon.png` and `assets/images/app_logo.png` if the application logo changes; rerun `dart run flutter_launcher_icons` afterward.
