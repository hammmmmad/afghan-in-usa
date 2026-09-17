# Deploys the send-push Edge Function and sets the FCM secret.
# Run from Android Studio PowerShell in the project root:
#   .\deploy-send-push.ps1
# If scripts are blocked, run instead:
#   powershell -ExecutionPolicy Bypass -File .\deploy-send-push.ps1

param(
  [string]$ServiceAccountPath = "$env:USERPROFILE\Downloads\afghan-in-usa-firebase-adminsdk-fbsvc-bf0ea9abc1.json"
)

$ErrorActionPreference = 'Stop'
$ProjectRef = 'uqwcahtlnaodaeusmzmm'

if (-not (Test-Path $ServiceAccountPath)) {
  Write-Host "Service account key not found:" $ServiceAccountPath -ForegroundColor Red
  Write-Host "Download it once from Firebase Console > Project Settings > Service accounts > Generate new private key," -ForegroundColor Yellow
  Write-Host "then re-run:  .\deploy-send-push.ps1 -ServiceAccountPath <full-path-to-json>" -ForegroundColor Yellow
  exit 1
}

# 1) Log in to Supabase (opens the browser once).
supabase login

# 2) Link this repository to the dashboard project.
supabase link --project-ref $ProjectRef

# 3) Deploy the Edge Function.
supabase functions deploy send-push

# 4) Upload the FCM secret. The JSON is flattened to one line inside a temp
#    env file so quoting can never corrupt the private key.
$json = (Get-Content -Raw $ServiceAccountPath).Trim() -replace '\r?\n', ''
$envFile = Join-Path $env:TEMP 'supabase-fcm-secret.env'
[System.IO.File]::WriteAllText($envFile, "FCM_SERVICE_ACCOUNT_JSON=$json")
supabase secrets set --env-file $envFile
Remove-Item $envFile

Write-Host ''
Write-Host 'Done: send-push is deployed and FCM_SERVICE_ACCOUNT_JSON is set.' -ForegroundColor Green
Write-Host 'Personal and public push notifications are now live.' -ForegroundColor Green
