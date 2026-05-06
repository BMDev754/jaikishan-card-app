# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Play Store Split Support
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Razorpay SDK ProGuard Rules
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# ProGuard Annotations
-dontwarn proguard.annotation.**
-keep class proguard.annotation.** { *; }

# Local Auth
-keep class androidx.biometric.** { *; }
-keep class androidx.fragment.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Permissions
-keep class com.baseflow.permissionhandler.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Flutter Contacts
-keep class co.sunnyapp.flutter_contacts.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Mobile Scanner
-keep class dev.steenbakker.mobile_scanner.** { *; }

# QR Flutter
-keep class net.touchcapture.qr.flutterqr.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Fluttertoast
-keep class io.github.ponnamkarthik.toast.fluttertoast.** { *; }

# General Android Rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exception

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from removing classes with reflection
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Gson specific classes
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Keep all classes in the main package
-keep class com.jaikisan.jaikisan_card.** { *; }
