# Supabase / FCM manual setup

> **Status: DONE (2026-09-15).** The `send-push` Edge Function is deployed
> on project `uqwcahtlnaodaeusmzmm` and the `FCM_SERVICE_ACCOUNT_JSON`
> secret is set. Live check: POST to `/functions/v1/send-push` returns
> `{"error":"Unauthorized"}` (expected without an admin JWT) instead of 404.
> To redeploy after changing `supabase/functions/send-push/index.ts`, run
> `.\deploy-send-push.ps1` or the manual commands below.

```powershell
cd "C:\Afghan in USA"
.\deploy-send-push.ps1
```

It expects the Firebase service-account key at
`%USERPROFILE%\Downloads\afghan-in-usa-firebase-adminsdk-fbsvc-bf0ea9abc1.json`
(pass `-ServiceAccountPath <path>` to override). If scripts are blocked:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy-send-push.ps1
```

The equivalent manual commands:

```powershell
supabase login
supabase link --project-ref uqwcahtlnaodaeusmzmm
supabase functions deploy send-push
# then set FCM_SERVICE_ACCOUNT_JSON from the service-account JSON file
```

The current project has exactly one administrator table: `public.admin_users`.
There is no `app_admins` table in the project migrations, so do not create a
second table. After the migration, add the administrator's Supabase
`auth.users.id` to `public.admin_users` in the Supabase SQL editor. Do not put a service-role key
in Flutter, HTML, GitHub, or this file.

Documents use a private `documents` Storage bucket. The app obtains a one-hour
Signed URL only after Supabase Google authentication; the database metadata is
publicly readable only for `status = published`. Files are not public URLs.

Google Sign-In runs on Firebase Auth (`signInWithCredential`). The same
Google ID token then opens a Supabase session (`signInWithIdToken`) so the
Supabase-backed features (document signed URLs, device tokens, case
subscriptions, special notifications, admin checks) keep working. Firebase
is the only sign-in surface the user sees; the Supabase step is silent.

## Local Android run with Supabase

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://uqwcahtlnaodaeusmzmm.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_GF5HEOLIzABEsJxKeHaUmg_iUWd3YGl
```

Offline startup is hang-proof: `main()` wraps Firebase/Supabase/Storage init
in timeouts and pushes FCM off the critical path, so the app always reaches
the first frame with bundled content (2026-09-15).

## Release APK command

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:GRADLE_USER_HOME=(Join-Path (Get-Location) '.gradle-local')
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://uqwcahtlnaodaeusmzmm.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_GF5HEOLIzABEsJxKeHaUmg_iUWd3YGl
```

Output: `build\app\outputs\flutter-apk\app-release.apk`.

Push delivery requires Firebase Cloud Messaging enabled, Android SHA-1/SHA-256
and the server-only `FCM_SERVICE_ACCOUNT_JSON` Edge Function secret. Google Play
requires a final application id, signing key backup, privacy policy, Data safety
declaration, notification permission explanation, and store screenshots.
