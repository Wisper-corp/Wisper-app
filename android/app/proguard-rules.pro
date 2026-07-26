# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# flutter_callkit_incoming — keep all classes, suppress old coil warning
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-dontwarn coil.bitmap.BitmapPool
-dontwarn coil.**

# SmileID SDK — keep all classes to prevent startup crash
-keep class com.smileidentity.** { *; }
-keep class com.smileidentity.flutter.** { *; }
-keepclassmembers class com.smileidentity.** { *; }
-dontwarn com.smileidentity.**

# Firebase / FCM
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep all plugin method channels
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# Retrofit
-keepattributes RuntimeVisibleAnnotations, RuntimeInvisibleAnnotations
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# General — keep all classes that could be loaded reflectively
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
