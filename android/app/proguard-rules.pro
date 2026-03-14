# Flutter (used when minifyEnabled is true)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.** { *; }

# App Activity (MethodChannel)
-keep class com.applooms.bundlesnap.MainActivity { *; }

# Keep native methods
-keepclasseswithmembernames class * { native <methods>; }
