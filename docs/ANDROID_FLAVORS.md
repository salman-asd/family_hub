# Android flavors (dev / prod)

The flavors are already configured in `android/app/build.gradle.kts`
(or `build.gradle` on older Flutter templates) inside `android { ... }`:

```kotlin
flavorDimensions += "env"
productFlavors {
    create("dev") {
        dimension = "env"
        applicationIdSuffix = ".dev"
        resValue("string", "app_name", "Family Hub (dev)")
    }
    create("prod") {
        dimension = "env"
        resValue("string", "app_name", "Family Hub")
    }
}
```

In `android/app/src/main/AndroidManifest.xml` set
`android:label="@string/app_name"` on `<application>`.

Verify: `flutter run --flavor dev -t lib/main_dev.dart` shows
"Family Hub (dev)" as the launcher label and "dev" on screen.
