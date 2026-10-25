import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKey = Properties()
val releaseKeyFile = rootProject.file("key.properties")
if (releaseKeyFile.exists()) releaseKeyFile.inputStream().use { releaseKey.load(it) }

android {
    namespace = "de.numpy.orbital.atomic_orbital"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "de.numpy.orbital.orbital4"
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

    flavorDimensions += "distribution"
    productFlavors {
        create("production") { dimension = "distribution" }
        create("comparison") {
            dimension = "distribution"
            applicationId = "de.numpy.orbital.atomic_orbital"
        }
    }

    signingConfigs {
        create("release") {
            storeFile = releaseKey.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = releaseKey.getProperty("storePassword")
            keyAlias = releaseKey.getProperty("keyAlias")
            keyPassword = releaseKey.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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

tasks.configureEach {
    if (name.endsWith("ReleaseBundle") ||
        (name.startsWith("package") && name.endsWith("Release"))) {
        doFirst {
            check(listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
                .all { !releaseKey.getProperty(it).isNullOrBlank() }) {
                "Release signing requires android/key.properties with the registered Play upload key."
            }
        }
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-games-v2:22.1.0")
    testImplementation("junit:junit:4.13.2")
}
