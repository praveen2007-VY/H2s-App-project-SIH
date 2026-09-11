# H₂S Safety Platform — Professional Flutter Product Scaffold

This project is a redesigned implementation scaffold based on the supplied 64-screen H₂S Safety Platform specification. It includes a functional worker flow, admin/manager experience, scanner input, prototype color-analysis results, analytics, alerts, location, reports, RBAC model, and a Supabase-ready schema.

## Important safety note
The strip analysis in this project is **prototype decision-support logic**. It is not a certified H₂S gas detector and must not be used for life-safety decisions until validated against controlled calibration data, reference measurements, device/lighting variations, strip batches, and applicable industrial safety requirements.

## What is implemented
- Worker login + registration UI
- Worker dashboard, profile, settings, history, analytics, alerts, notifications
- Camera/gallery strip capture via `image_picker`
- Image review and prototype RGB/HSV/Lab analysis pipeline UI
- Safe / Warning / Critical classification driven by a configurable prototype index
- Location permission + current location capture
- PDF preview/print flow and CSV generation flow
- Admin/manager login and responsive dashboard
- Worker management, exposure analytics, critical alert timeline, devices, locations, reports
- 64 named routes matching the product blueprint; fully reusable placeholder screens are provided for the deeper administration/system modules
- Supabase/Postgres schema with RLS-oriented role model and storage buckets

## Prerequisites
Install Flutter 3.38+ / Dart 3.12+ or newer, Android Studio, Android SDK, and VS Code with the Flutter/Dart extensions.

## First-time setup on Windows
Because platform folders are intentionally generated from the Flutter SDK on your machine, run the setup script once:

```powershell
cd C:\path\to\H2S-Safety-Platform-Pro
.\tooling\setup_platforms.ps1
```

This runs `flutter create .` and then prints the Android/iOS permission changes required by this project.

### If PowerShell blocks the script
Use the built-in commands directly:

```powershell
flutter create .
flutter pub get
```

Then add the permissions from `docs/platform_permissions.md`.

## Run on your connected Android phone

```powershell
flutter devices
flutter pub get
flutter run -d YOUR_DEVICE_ID
```

Example:

```powershell
flutter run -d RZGL613EF4J
```

## Demo login
Worker:
- Username: `worker`
- Password: `1234`

Admin/Manager:
- Username: `admin`
- Password: `admin123`

These are local demo credentials only. Replace with Supabase Auth in production.

## Supabase
1. Create a Supabase project.
2. Open `supabase/schema.sql` and run it in the SQL Editor.
3. Add your project URL and publishable key in `lib/config/app_config.dart`.
4. Enable Supabase Auth providers required by your organization.
5. Create Storage buckets listed in the schema and configure policies.

The app is deliberately usable in **demo/offline mode** when Supabase is not configured.

## Camera
The app uses the official `image_picker` camera/gallery API. On Android, `android/app/src/main/AndroidManifest.xml` must include camera permission. On iOS, add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` as described in `docs/platform_permissions.md`.

## Product architecture
The screen IDs, workflows, data relationships, storage model, RBAC direction, scan workflow, critical alert workflow, location policy, report structure, responsive breakpoints, and safety assumptions follow the uploaded specification. In particular, the scan record links worker/device/image/color values/prediction/risk/location/model version, and the system keeps model/calibration version on every prediction.

## Recommended development order
1. Foundation/Auth/Supabase/RLS
2. Worker end-to-end workflow
3. Scanner/image quality engine
4. Persistence + realtime + alerts
5. Admin monitoring
6. Reports + exports
7. Calibration/model validation + production hardening
