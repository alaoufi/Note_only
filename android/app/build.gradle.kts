import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// إعداد التوقيع يُقرأ من ملف محليّ غير متعقَّب: android/key.properties (انظر
// key.properties.example). لا تُلتزم مفاتيح التوقيع أو كلماتها في المستودع.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    // تحذير بارز: بناء إصدار بلا مفتاح النشر يوقّع بمفتاح debug، فلن يُثبَّت فوق
    // النسخة الموقّعة بمفتاح النشر (خطر عدم القدرة على التحديث دون حذف التطبيق).
    logger.warn("⚠️  android/key.properties مفقود — سيُوقَّع الإصدار بمفتاح debug. " +
        "للنشر: ضع alaoufi-release.jks و key.properties بمفتاح النشر نفسه كي " +
        "تُثبَّت التحديثات فوق القديم دون فقدان بيانات المستخدمين.")
}

android {
    namespace = "com.mudhakkarati.app"
    compileSdk = 36 // مطلوب من بعض الإضافات (flutter_plugin_android_lifecycle)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // مطلوب لـ flutter_local_notifications (تكسير مكتبات Java الحديثة).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.alaoufi.notes"
        minSdk = 26 // Android 8.0
        // مستوى مستهدف حديث مطلوب لقبول Google Play (يتطلب 34+ للتطبيقات الجديدة).
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // إعداد التوقيع يأتي من key.properties المحليّ (غير متعقَّب). لتوقيع نفس
    // المفتاح دائمًا — كي تُثبَّت التحديثات فوق بعضها بلا خطأ «توقيع غير متطابق» —
    // ضع alaoufi-release.jks و key.properties محليًّا (من نسختك الاحتياطية).
    signingConfigs {
        if (hasKeystore) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // عند غياب key.properties نرجع لتوقيع debug كي لا ينكسر البناء أثناء
            // التطوير — لكن **الإصدار الرسميّ يجب أن يُبنى مع key.properties** كي
            // يوقَّع بمفتاح النشر الصحيح.
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // نعطّل التقليص حتى لا تُحذف أكواد تحتاجها الإضافات (سبب محتمل للانهيار).
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
