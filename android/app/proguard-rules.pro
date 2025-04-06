# Keep all Firebase-related classes
-keep class com.google.firebase.** { *; }

# Keep all TableCalendar classes (if you're using it)
-keep class com.tablecalendar.** { *; }

# Keep Flutter plugin classes
-keep class io.flutter.** { *; }

# Keep your app's main package classes
-keep class com.example.yourapp.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable { *; }

# Keep Google Play Core classes
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**