$ErrorActionPreference = 'Stop'
Write-Host 'Checking Flutter...'
flutter --version
Write-Host 'Generating missing Flutter platform folders...'
flutter create .
Write-Host ''
Write-Host 'Next: add permissions from docs/platform_permissions.md, then run:'
Write-Host '  flutter pub get'
Write-Host '  flutter run'
