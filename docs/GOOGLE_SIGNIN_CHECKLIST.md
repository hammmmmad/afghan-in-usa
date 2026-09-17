# چک‌لیست فعال‌سازی Google Sign-In (Firebase + Supabase)

> **وضعیت: کامل انجام شد (2026-09-15).** Google provider در Firebase فعال است،
> هر سه اثر انگشت (SHA-1 دیباگ، SHA-1 ریلیس، SHA-256 ریلیس) ثبت شده‌اند و
> `google-services.json` جدید با کلاینت OAuth ریلیس در `android/app/` نصب شده.
> Google provider در Supabase هم فعال است (برای نشست بی‌صدای Supabase).

ورود با گوگل با **Firebase Auth** انجام می‌شود. همان توکن گوگل بی‌صدا یک
نشست Supabase هم می‌سازد تا قابلیت‌های وابسته به Supabase (دانلود اسناد
خصوصی، نوتیفیکیشن اختصاصی پرونده‌ها، ثبت توکن پوش هر کاربر و چک ادمین)
دوباره کار کنند.

## مقادیر پروژه

| مورد | مقدار |
|---|---|
| Firebase Project | `afghan-in-usa` (شماره: `318374626413`) |
| Package Name اندروید | `com.afghan_in_usa` |
| Web Client ID (serverClientId در `lib/services/auth_service.dart`) | `318374626413-r3rbfcv35b7953rv086ic61fukf7bphe.apps.googleusercontent.com` |
| Android Client ID (در `google-services.json` موجود است) | `318374626413-dkfd028029ja34lfg2q8i7rvbqdf5d0q.apps.googleusercontent.com` |
| SHA-1 کلید Release (`upload-keystore.jks`) | `14:E5:0D:6A:DA:61:D4:14:6C:4F:F0:F0:1B:53:98:12:ED:FB:42:9F` |
| SHA-1 کلید Debug (`%USERPROFILE%\.android\debug.keystore`) | `CD:78:90:1A:CF:71:F3:90:8F:BD:0F:CE:C2:B9:26:40:15:ED:FD:4D` |

## مرحله ۱ — فعال کردن Google در Firebase Authentication

1. https://console.firebase.google.com → پروژه `afghan-in-usa`
2. منوی **Authentication → Sign-in method**
3. روی **Add new provider → Google** بزنید و **Enable** کنید
   (Web Client ID و Secret را خودکار پر می‌کند؛ چیزی دستی لازم نیست)
4. یک حساب پشتیبان (support email) انتخاب کنید و ذخیره کنید

## مرحله ۲ — مطمئن شدن از ثبت SHA-1

`google-services.json` موجود در `android/app/` از قبل یک Android OAuth
client دارد، پس SHA-1 احتمالاً ثبت شده. برای اطمینان:

1. **Project Settings (⚙) → Your apps → اپ اندروید**
2. هر دو اثر انگشت را اضافه کنید:
   - SHA-1 **Release** (بالا) — برای APK امضاشده
   - SHA-1 **Debug** (بالا) — برای `flutter run`
3. اگر SHA-1 جدیدی اضافه کردید، حتماً دکمه **google-services.json download**
   را بزنید و فایل جدید را در `android/app/` جایگزین کنید.

## مرحله ۳ — فعال کردن Google در Supabase (برای اسناد و نوتیفیکیشن‌ها)

بدون این مرحله ورود کار می‌کند ولی دانلود اسناد خصوصی، نوتیفیکیشن
اختصاصی و ثبت توکن پوش کار نمی‌کنند:

1. https://supabase.com/dashboard → پروژه → **Authentication → Sign In / Providers**
2. **Google** را روشن کنید و وارد کنید:
   - Client ID: `318374626413-r3rbfcv35b7953rv086ic61fukf7bphe.apps.googleusercontent.com`
   - Client Secret: از همان Web client در Google Cloud Console
3. ذخیره کنید.

اگر این مرحله انجام نشود، ورود با گوگل (Firebase) همچنان کار می‌کند؛ فقط
قابلیت‌های Supabase در حالت مهمان می‌مانند.

## تست

```powershell
flutter run
```

(برای خبر و داده‌های Supabase همان‌طور که قبل بود `--dart-define`های
SUPABASE_URL و SUPABASE_ANON_KEY را اضافه کنید — ولی ورود با گوگل به آن
نیازی ندارد.)

روی دستگاه: دکمه «ورود با گوگل» در صفحه پروفایل یا اسناد → پنجره گوگل باز
می‌شود → بعد از انتخاب حساب، نام و ایمیل در پروفایل نمایش داده می‌شود.

خطاهای رایج:

- `ApiException: 10 (DEVELOPER_ERROR)` → SHA-1 دستگاه اجراکننده در Firebase
  ثبت نیست یا `google-services.json` قدیمی است.
- `UNREGISTERED_ON_API_CONSOLE` → همان مورد؛ SHA-1 جدید را اضافه و json را
  دوباره دانلود کنید.

## تغییرات کد (اشاره)

- `lib/services/auth_service.dart` — ورود با `FirebaseAuth.signInWithCredential`
  و سپس ساخت نشست Supabase با همان توکن (`signInWithIdToken`)
- `lib/pubspec.yaml` — افزودن `firebase_auth`
- `lib/screens/documents_screen.dart` — شرط ورود از جلسه Firebase خوانده می‌شود
- دانلود اسناد، توکن پوش، اشتراک پرونده‌ها و نوتیفیکیشن اختصاصی همان مسیر
  Supabase قبلی را دارند و با نشست بازگردانده‌شده کار می‌کنند.
