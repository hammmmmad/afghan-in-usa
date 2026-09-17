# Afghan in USA — Flutter (Dart) App

راهنمای مهاجرت افغان‌ها در آمریکا · Immigration news & guidance app
**Developer:** Sarfraz Khamoosh · **Version:** 2026.1.0+20260902

---

## ۱. این بسته چیست؟ / What is this?

پروژه کامل **Flutter/Dart** ساخته‌شده از روی نقشه ذهنی (mind map)، متن‌های خبری،
راهنمای پرونده‌ها، آیکن‌ها، آواتارها، فونت‌ها و انیمیشن Lottie که خودت فرستادی.
تمام کدها واقعی و کامل هستند (بدون TODO).

A complete Flutter/Dart project generated from your mind map, news texts, case
guides, icons, avatars, fonts and Lottie splash animation. All code is real and
complete (no TODO placeholders).

---

## ۲. اجرا کردن پروژه / Run it

```bash
# 1) وارد پوشه پروژه شو
cd afghan_in_usa

# 2) پوشه‌های android/ios را بساز (فقط یک بار)
# Current stable Flutter/Dart, with Android Studio + JDK 17
flutter channel stable
flutter upgrade
flutter create --org com.sarfrazkhamoosh --project-name afghan_in_usa --platforms=android,ios .

# 3) پکیج‌ها را نصب کن
flutter pub get

# 4) آیکن اپ را بساز
dart run flutter_launcher_icons

# 5) اجرا
flutter run
```

> مرحله ۲ فقط فایل‌های پلتفرم (android/, ios/) را اضافه می‌کند و به `lib/`،
> `assets/` یا `pubspec.yaml` دست نمی‌زند.
> Step 2 only adds the platform folders; it never touches `lib/`, `assets/`
> or `pubspec.yaml`.

پس از مرحله ۲، فایل `platform_setup/README.md` را بخوان (اجازه اینترنت،
تنظیم Google Sign-In، Info.plist).

اگر روی ویندوز هستی، فایل `pubspec.lock` خراب قدیمی را پاک کن؛ این پروژه عمداً
lockfile ندارد تا با Flutter stable سال ۲۰۲۶ دوباره resolve شود:

```powershell
Remove-Item pubspec.lock -Force -ErrorAction SilentlyContinue
flutter pub get
```

---

## ۳. چه چیزی داخل اپ است؟ / What's inside

| بخش | جزئیات |
|---|---|
| **Splash** | انیمیشن Lottie خودت (`assets/animations/splash.json`, ۱۰۸۰×۱۹۲۰, ۶۰fps) + fade به صفحه اصلی |
| **Bottom Nav** | نوار شیشه‌ای (glassmorphism) با ناچ منحنی + حباب صورتی شناور، انیمیشن `elasticOut` ۳۰۰ms، آیکن فعال سفید داخل حباب، آیکن‌های غیرفعال خاکستری |
| **Home** | فید خبری از ۷ خبر خودت، جستجو، pull-to-refresh، اسکرول بی‌نهایت (صفحه‌بندی ۴ تایی)، انیمیشن fade-in کارت‌ها، عکس ناشر/پروفایل سازنده + «Sarfraz Khamoosh»، بج دسته‌بندی |
| **Cases** | ۱۳ پرونده با زنگوله اطلاع‌رسانی (خاکستری/سبز) که در Hive ذخیره می‌شود |
| **Case Detail** | تایم‌لاین گام‌به‌گام (مثلاً SIV = ۱۴ مرحله)، نکات مهم در ExpansionTile، خبرهای مرتبط |
| **Documents** | ۱۰ سند با گیت ورود: مهمان → مودال Google Sign-In → دانلود؛ شمارنده دانلود در Hive |
| **Top bar** | فقط بعد از ورود: عکس گوگل + نام + زنگوله با بج، انیمیشن slide-down، قابل بستن |
| **Profile** | ۲۴ آواتار افغانی، نام/تخلص/شماره تماس، ایمیل گوگل، پرونده‌های دنبال‌شده |
| **Settings** | دارک/لایت + حالت سیستم، دو زبان (دری/English با RTL/LTR)، آب‌وهوا (Open-Meteo، بدون API key)، ماشین حساب، شریک‌سازی، نسخه، سازنده + ۹ لینک شبکه اجتماعی |

### پرونده‌ها / Cases (13)
SIV · P-1 · P-2 · I-730 · Humanitarian Parole · Re-Parole · DV Lottery ·
Sponsorship by U.S. Citizen · Sponsorship by Green Card / SIV · K-1 · CR-1 ·
Lautenberg Amendment · Scholarships in the U.S.

---

## ۴. ساختار / Structure

```
lib/
├── main.dart                 # MultiProvider + init
├── app.dart                  # MaterialApp, theme, locale, RTL
├── l10n/                     # app_fa.arb, app_en.arb + app_localizations.dart
├── models/                   # news, case, document, user, weather
├── providers/                # theme, language, auth, notification, download
├── screens/                  # splash, main_shell, home, news_detail, cases,
│                             # case_detail, documents, profile, settings
├── services/                 # auth, api, weather, storage, notification, download
├── theme/                    # app_theme, light_theme, dark_theme
├── utils/                    # constants (colors, assets, keys), helpers
└── widgets/                  # curved_bottom_nav_bar, news_card, case_card,
                              # notification_bell, document_card, top_notification_bar,
                              # google_sign_in_modal, afghan_avatar_selector,
                              # weather_widget, calculator_widget, loading_skeleton,
                              # tinted_icon, fade_in_up
assets/
├── animations/splash.json
├── avatars/avatar_01..24
├── cases/index.json + 13 case files
├── data/news.json, documents.json
├── images/{nav,settings,cases,documents,profile,news}/ + app_logo.png, app_icon.png, creator_profile.png, published_news.png
└── news/news1..6.jpeg
assets/fonts/  title.ttf (Persian news titles), news.ttf (Persian news body),
        Magazine .otf (English), navigation.otf (Navigation Bar), + legacy bundled fonts
```

### Provided assets status
- `assets/images/app_icon.png` and `assets/images/app_logo.png` use the supplied `icon_application.png` exactly.
- `assets/images/creator_profile.png` is an explicit generic placeholder because a separate creator photo was not present in the uploaded files. Replace it later with the real creator photo.
- `assets/images/published_news.png` is an explicit generic placeholder because a separate Published News photo was not present in the uploaded files. Replace it later with the real image.
- `assets/fonts/title.ttf` = Jomhuria (Persian news title role).
- `assets/fonts/news.ttf` = Estedad Light (Persian news body role).
- `assets/fonts/Magazine .otf` = Asikue Trial Medium (English role).
- `assets/fonts/navigation.otf` = Dunkin Sans (Navigation Bar role).

---

## ۵. محتوا را چطور تغییر بدهم؟ / Editing content

* **خبر جدید:** یک آبجکت به `assets/data/news.json` اضافه کن (`id`, `dateFa`, `dateEn`,
  `dateIso`, `titleFa`, `titleEn`, `summaryFa`, `summaryEn`, `contentFa[]`,
  `contentEn[]`, `image`, `category`, `publisher`, `source`). عکس را در `assets/news/` بگذار.
* **پرونده جدید:** فایل `assets/cases/<id>.json` بساز و در `assets/cases/index.json`
  ثبتش کن. `icon` یکی از کلیدهای `caseIconFor()` در `widgets/case_card.dart` است.
* **سند جدید:** به `assets/data/documents.json` اضافه کن (`url` مستقیم PDF = دانلود
  داخلی، لینک عادی = باز شدن در مرورگر).
* **ترجمه:** کلیدها در `lib/l10n/app_localizations.dart` (و همان‌ها در فایل‌های
  `.arb`). رابط کاربری دو زبان دارد؛ داده‌های پرونده‌ها با ساختار `{fa, en}` نگهداری می‌شوند و هر مقدار انگلیسیِ موجود هنگام انتخاب English نمایش داده می‌شود. برخی متن‌های پرونده که در بسته اصلی ترجمه انگلیسی نداشتند، همچنان به مقدار فارسی fallback می‌شوند.
* **لینک‌های شبکه اجتماعی:** `AppConfig.socials` در `lib/utils/constants.dart`.
* **آیکن اپ:** `assets/images/app_icon.png` را با لوگوی خودت عوض کن و
  `dart run flutter_launcher_icons` را دوباره اجرا کن.

### Supabase news publishing

The public News feed is production-ready for Supabase while retaining bundled
JSON as an offline fallback. Apply
all migrations in `supabase/migrations/` with the Supabase CLI. The newest
migration also creates private document storage, public/special notification
tables, FCM device-token metadata, administrator roles, and their RLS rules.

Build or run without committing credentials:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Only articles whose `status` is `published` and have `published_at` set are
visible to the app. New articles must use bilingual titles/summaries and JSON
paragraph arrays in `content_fa` and `content_en`. The app always renders the
bundled `assets/images/creator_profile.png` and `Sarfraz Khamoosh` as the
publisher, regardless of any remote avatar value.

To enable the administrator upload panel, configure Google as a Supabase auth
provider and add the administrator's Supabase `auth.users.id` to
`public.admin_users`. Never put a service-role key in Flutter, HTML, or Git.
Set `FCM_SERVICE_ACCOUNT_JSON` only as an Edge Function secret, then deploy
`supabase/functions/send-push`. Public pushes use the `public-news` topic;
special pushes are sent only to the active case subscription of the recipient.

---

## ۶. نکته‌ها / Notes

* **Google Sign-In** برای اجرا روی دستگاه واقعی نیاز به SHA-1 و
  `google-services.json` دارد → `platform_setup/README.md`.
* **آب‌وهوا** از Open-Meteo استفاده می‌کند، بنابراین به API key نیاز ندارد.
* محتوای حقوقی این اپ اطلاعات عمومی است، نه مشاوره حقوقی (در UI هم نوشته شده).
