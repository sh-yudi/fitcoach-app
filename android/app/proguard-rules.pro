# --- Flutter engine (always keep) ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# --- Google Mobile Ads SDK (google_mobile_ads plugin) ---
-keep public class com.google.android.gms.ads.** { public *; }
-keep public class com.google.ads.** { public *; }
-keep class com.google.android.gms.ads.AdView { *; }
-dontwarn com.google.android.gms.ads.**

# --- Room database generated implementations ---
# WorkManager (used by the Ads SDK) creates androidx.work.impl.WorkDatabase via
# Room reflection. R8 stripping these classes causes a release-only crash:
#   "Failed to create an instance of androidx.work.impl.WorkDatabase"
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class *
-keep @androidx.room.Dao class *
-keep @androidx.room.Database class *
-keepclassmembers class * {
    @androidx.room.* <methods>;
    @androidx.room.* <fields>;
}

# --- WorkManager ---
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
-dontwarn org.conscrypt.**
