# Smart City – Sistem Pelaporan Fasilitas Publik

## Cara pakai
1. Salin folder `lib/` dan `test/` ke proyek Flutter
2. Pastikan `pubspec.yaml` punya dependency berikut, lalu jalankan perintah di bawah:

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.4.5
  path: ^1.9.1
  sqflite_common_ffi_web: ^1.2.0
```

```powershell
flutter pub get
dart run sqflite_common_ffi_web:setup
dart format lib
flutter analyze
flutter run -d chrome --web-port=8080
flutter build apk --release
```

Catatan:
- `test/widget_test.dart` meng-import `package:smart_city/main.dart`. Ganti `smart_city`
  dengan `name:` di pubspec.yaml kamu.
- Kode memakai `initialValue` pada DropdownButtonFormField (Flutter 3.35+). Jika Flutter kamu
  lebih lama dan muncul error, ganti `initialValue:` menjadi `value:`.
