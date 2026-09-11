# Platform permissions

## Android
After `flutter create .`, edit `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

For foreground/background location behavior, extend this only after defining the organization's actual operational policy. Do not continuously track GPS unnecessarily.

## iOS
In `ios/Runner/Info.plist` add:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is used to capture H₂S test-strip images for analysis.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is used to select H₂S test-strip images.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to associate safety scans and alerts with the current work area.</string>
```
