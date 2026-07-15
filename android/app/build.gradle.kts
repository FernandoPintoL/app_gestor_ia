plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fpl.topicos.gestor_ia"
    compileSdk = 36
    ndkVersion = "29.0.13113456"  // Required by whisper_ggml

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fpl.topicos.gestor_ia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // whisper_ggml calls into ffmpeg_kit_flutter_new_min (an fork of the now
    // archived/unmaintained arthenica/ffmpeg-kit) on every transcription.
    // Its prebuilt libffmpegkit_abidetect.so crashes on some Samsung devices
    // in release builds with "Bad JNI version returned from JNI_OnLoad" when
    // loaded via AGP's modern (uncompressed, mmap-from-APK) native lib
    // packaging. Forcing legacy packaging (compressed, extracted at install
    // time) is the standard workaround for this class of OEM-specific native
    // loading bug.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
