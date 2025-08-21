# fitatu_barcode_scanner

Flutter barcode scanner implementation based on ZXING

## Getting Started

To work with native plugin code:

1. Go to the `zxing-cpp/wrappers/flutter/example`
2. Run `flutter build apk --config-only`
3. Select **Open an existing Android Studio Project** in the **Welcome to Android Studio** dialog, or select **File > Open** from the menu, and select the `hello/example/android/build.gradle` file.
4. In the **Gradle Sync** dialog, select OK.
5. In the **Android Gradle Plugin Update** dialog, select **Don't remind me again for this project.**

## Pigeon

To generate pigeon interfaces run:

```bash
dart run pigeon --input=pigeons/api.dart
```