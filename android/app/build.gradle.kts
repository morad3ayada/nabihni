plugins {
    id("com.android.application")
    id("kotlin-android")
    // لازم نضيف هنا بلجن جوجل سيرفيس
    id("com.google.gms.google-services")
    // بلجن فلاتر
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nabihni"
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
        applicationId = "com.example.nabihni"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
