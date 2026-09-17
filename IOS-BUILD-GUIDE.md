# راهنمای خروجی iOS — اپ Afghan In USA

## چه چیزی آماده شد (روی ویندوز)

- کل پروژه Xcode تولید شد: `ios/Runner.xcodeproj` و `ios/Runner.xcworkspace`
- **Bundle Identifier:** `com.afghaninusa` (یکسان با اندروید)
- **نام نمایشی:** Afghan In USA
- **حداقل iOS:** 15.0 (سازگار با Firebase Apple SDK 12)
- آیکون‌های iOS از `assets/images/app_icon.png` ساخته شد (بدون آلفا — مناسب App Store)
- فقط حالت عمودی برای آیفون (مطابق اندروید)
- `codemagic.yaml` برای ساخت ابری IPA اضافه شد

## محدودیت اصلی

ساخت فایل IPA فقط روی **macOS با Xcode** ممکن است. دو راه دارید:

### راه ۱ — Codemagic (بدون مک، توصیه‌شده)
1. کل پوشه پروژه را در GitHub/GitLab/Bitbucket بگذارید.
2. در [codemagic.io](https://codemagic.io) ثبت‌نام کنید (پلن رایگان: ۵۰۰ دقیقه در ماه).
3. اپ را اضافه کنید → workflow **«Afghan In USA — iOS Release»** را انتخاب کنید → Start build.
4. فایل IPA در بخش Artifacts دانلود می‌شود.

⚠️ برای نصب روی آیفون واقعی یا انتشار در App Store به **حساب Apple Developer (۹۹ دلار در سال)** و تنظیم امضا در Codemagic نیاز دارید. بدون آن فقط بیلد بدون امضا/شبیه‌ساز می‌گیرید.

### راه ۲ — مک
```bash
cd <پوشه پروژه>
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://uqwcahtlnaodaeusmzmm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_GF5HEOLIzABEsJxKeHaUmg_iUWd3YGl
```
خروجی: `build/ios/ipa/afghan_in_usa.ipa`

## کارهای باقی‌مانده برای iOS (لازم است قبل از انتشار)

1. **Firebase برای iOS:** در کنسول Firebase یک اپ iOS با bundle id `com.afghaninusa` بسازید و `GoogleService-Info.plist` را در `ios/Runner/` بگذارید، یا `flutterfire configure` را روی مک اجرا کنید. تا این کار انجام نشود، **پوش نوتیفیکیشن و Google Sign-In روی iOS کار نمی‌کنند** (اپ به‌صورت امن بدون این‌ها بالا می‌آید).
2. **Google Sign-In iOS:** در کنسول Google Cloud یک OAuth Client نوع iOS بسازید و در `ios/Runner/Info.plist` این دو را اضافه کنید:
   - `GIDClientID` با مقدار client id
   - `CFBundleURLTypes` با URL scheme معکوسِ client id
3. **پوش نوتیفیکیشن:** در Apple Developer یک APNs Key بسازید و در Firebase Console → Project Settings → Cloud Messaging آپلود کنید.
4. **امضا:** در Xcode (یا Codemagic) Team و Provisioning Profile را تنظیم کنید.

## نکته‌های امنیتی

- مقادیر `--dart-define` فوق فقط کلیدهای عمومی (publishable) Supabase هستند؛ کلید service role هیچ‌وقت داخل اپ قرار نمی‌گیرد.
