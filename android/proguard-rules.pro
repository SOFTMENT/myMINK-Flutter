# Recommended rules for Firebase Crashlytics
-keep class com.google.firebase.** { *; }
-keep class com.crashlytics.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.crashlytics.**
