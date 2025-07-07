plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase services
}

android {
    namespace = "com.example.manos_expertas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.manos_expertas"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuración de signing comentada temporalmente para desarrollo
    /*
    signingConfigs {
        create("release") {
            storeFile = rootProject.file("keystore/mi_key.jks")
            storePassword = "manos123"
            keyAlias = "manos_expertas"
            keyPassword = "manos123"
        }
    }
    */

    buildTypes {
        getByName("debug") {
            // Usar la configuración de debug por defecto (sin signing personalizado)
            isDebuggable = true
        }
        getByName("release") {
            // Solo usar signing personalizado en release si el keystore existe
            // signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
