import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadProperties = Properties()
val uploadPropertiesFile = rootProject.file("key.properties")
if (uploadPropertiesFile.isFile) {
    uploadPropertiesFile.inputStream().use { uploadProperties.load(it) }
}
val uploadFields = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasUploadSigning = uploadFields.all { !uploadProperties.getProperty(it).isNullOrBlank() }
val validateUploadSigning = tasks.register("validateUploadSigning") {
    doLast {
        check(hasUploadSigning) {
            "Release signing requires android/key.properties with storeFile, storePassword, keyAlias, and keyPassword. See README.md."
        }
        check(rootProject.file(uploadProperties.getProperty("storeFile")).isFile) {
            "The upload keystore configured in android/key.properties does not exist."
        }
    }
}

android {
    namespace = "io.pentacoxian.gglp"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required by flutter_local_notifications for date/time APIs
        // when minSdk is below 26.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "io.pentacoxian.gglp"
        minSdk = 21
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("upload") {
            if (hasUploadSigning) {
                storeFile = rootProject.file(uploadProperties.getProperty("storeFile"))
                storePassword = uploadProperties.getProperty("storePassword")
                keyAlias = uploadProperties.getProperty("keyAlias")
                keyPassword = uploadProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("upload")
        }
    }
    sourceSets.getByName("androidTest").assets.srcDir(layout.buildDirectory.dir("generated/update-test-assets"))
}

tasks.configureEach {
    if (name == "preReleaseBuild" || name == "validateSigningRelease") {
        dependsOn(validateUploadSigning)
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core:1.13.1")
    implementation("com.android.tools.build:apksig:8.9.1")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    // Backports java.time and other Java 8+ APIs to older Android (required
    // by flutter_local_notifications when minSdk < 26).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
