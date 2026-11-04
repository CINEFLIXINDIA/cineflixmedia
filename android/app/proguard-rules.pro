# WorkManager & Room rules (required when google_mobile_ads dependencies are linked)
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.work.**
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    <init>(...);
}

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

