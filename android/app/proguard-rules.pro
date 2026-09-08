# --- Flutter engine (always keep) ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# --- UCrop Image Cropper ---
-keep class com.yalantis.ucrop.** { *; }

# --- Biometrics & Local Auth ---
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }
