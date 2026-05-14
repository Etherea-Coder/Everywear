# Supabase
-keep class io.supabase.** { *; }
-keep class com.postgrest.** { *; }
-keep class com.goauth.** { *; }
-keep class io.github.jan.supabase.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Gson / JSON serialization
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Kotlin serialization
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

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Retrofit (if used by supabase_flutter internally)
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

# CachedNetworkImage
-keep class com.bumptech.glide.** { *; }

# Sentry
-dontwarn io.sentry.**
-keep class io.sentry.** { *; }

# General Flutter
-keep class * extends java.lang.reflect.** { *; }
-dontwarn java.lang.reflect.**

# Keep all models used with Map<String, dynamic>
-keepclassmembers class * {
    public <methods>;
}
