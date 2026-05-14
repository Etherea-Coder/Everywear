# Supabase - GoTrue auth, PostgREST, Realtime, Storage
-keep class io.supabase.** { *; }
-keep class com.postgrest.** { *; }
-keep class com.goauth.** { *; }
-keep class io.github.jan.supabase.** { *; }
-keep class com.supabase.** { *; }

# Flutter plugins - keep all plugin registrations
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * extends io.flutter.embedding.engine.plugins.PluginRegistry { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class **.Plugin { *; }
-keep class **.Plugin$* { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# flutter_appauth (used by supabase_flutter for OAuth)
-keep class net.openid.appauth.** { *; }
-keep class com.linusu.flutter_appauth.** { *; }

# google_sign_in
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# camera
-keep class io.flutter.plugins.camera.** { *; }

# flutter_image_compress
-keep class com.example.flutterimagecompress.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Google Play Core (deferred components, in-app updates)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Kotlin stdlib & coroutines
-dontwarn kotlinx.coroutines.**
-keep class kotlinx.coroutines.** { *; }

# Kotlin serialization - critical for Supabase
-keepattributes *Annotation*, InnerClasses
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
    *** serializers();
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keepclassmembers class * extends kotlinx.serialization.KSerializer {
    <methods>;
}
-keepclassmembers class * {
    @kotlinx.serialization.Serializable <fields>;
}

# Keep all @Serializable classes and their companions
-keep class * {
    @kotlinx.serialization.Serializable <fields>;
}
-keepclassmembers class * {
    *** Companion;
}
-keepnames class kotlinx.serialization.serializers.PrimitiveSerializers

# Gson
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# JWT / Auth0
-keep class com.auth0.** { *; }
-keep class io.jsonwebtoken.** { *; }
-keepnames class org.json.** { *; }

# Hive
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
    <methods>;
}

# CachedNetworkImage / Glide
-keep class com.bumptech.glide.** { *; }

# Sentry
-dontwarn io.sentry.**
-keep class io.sentry.** { *; }

# General
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes AnnotationDefault

# Native libraries
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enum
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# R8 compatibility
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.-KotlinExtensions
