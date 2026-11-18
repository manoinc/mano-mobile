import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for Play; key.properties is gitignored, see docs/develop/release-android.md.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.manoinc.mano.mano_requester"
    // flutter_secure_storage 11 requires API 37 to compile against, which is
    // ahead of the version Flutter currently defaults to. Pinned explicitly
    // rather than left to drift.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The Play listing's id: must match exactly, case included, and can never change.
        applicationId = "com.manoInc.mano"

        // No manifestPlaceholders for an OAuth redirect scheme here.
        // AppAuth's Gradle plugin needed one to register the custom-scheme
        // redirect it caught; whatever auth provider lands next may or may
        // not need the same thing, and adds it back only if it does.

        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keystoreProperties.getProperty("storeFile")?.let { storeFile = file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            // Falls back to debug keys without key.properties, so `flutter run --release` still works.
            if (keystoreProperties.isEmpty) {
                logger.warn("key.properties not found: release is debug-signed and Play will reject it.")
            }
            signingConfig = signingConfigs.getByName(
                if (keystoreProperties.isEmpty) "debug" else "release"
            )
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
