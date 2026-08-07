import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Carrega as propriedades da chave
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.gusoliveira21.memoryflash"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.gusoliveira21.memoryflash"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    implementation("com.google.android.material:material:1.12.0")
}

flutter {
    source = "../.."
}

// Assina AABs automaticamente após o build apenas se o keystore existir
if (keystorePropertiesFile.exists()) {
    afterEvaluate {
        tasks.named("bundleDebug")?.configure {
            doLast {
                val aabFile = file("${project.buildDir}/outputs/bundle/debug/app-debug.aab")
                if (aabFile.exists()) {
                    exec {
                        commandLine(
                            "jarsigner", "-verbose", "-sigalg", "SHA256withRSA", "-digestalg", "SHA-256",
                            "-keystore", keystoreProperties["storeFile"] as String,
                            "-storepass", keystoreProperties["storePassword"] as String,
                            "-keypass", keystoreProperties["keyPassword"] as String,
                            aabFile.absolutePath, keystoreProperties["keyAlias"] as String
                        )
                    }
                }
            }
        }
        tasks.named("bundleRelease")?.configure {
            doLast {
                val aabFile = file("${project.buildDir}/outputs/bundle/release/app-release.aab")
                if (aabFile.exists()) {
                    exec {
                        commandLine(
                            "jarsigner", "-verbose", "-sigalg", "SHA256withRSA", "-digestalg", "SHA-256",
                            "-keystore", keystoreProperties["storeFile"] as String,
                            "-storepass", keystoreProperties["storePassword"] as String,
                            "-keypass", keystoreProperties["keyPassword"] as String,
                            aabFile.absolutePath, keystoreProperties["keyAlias"] as String
                        )
                    }
                }
            }
        }
        tasks.named("bundleProfile")?.configure {
            doLast {
                val aabFile = file("${project.buildDir}/outputs/bundle/profile/app-profile.aab")
                if (aabFile.exists()) {
                    exec {
                        commandLine(
                            "jarsigner", "-verbose", "-sigalg", "SHA256withRSA", "-digestalg", "SHA-256",
                            "-keystore", keystoreProperties["storeFile"] as String,
                            "-storepass", keystoreProperties["storePassword"] as String,
                            "-keypass", keystoreProperties["keyPassword"] as String,
                            aabFile.absolutePath, keystoreProperties["keyAlias"] as String
                        )
                    }
                }
            }
        }
    }
}
