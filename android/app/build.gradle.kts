import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de release: lida de android/key.properties, que fica fora do
// repositório (o .gitignore barra o arquivo e o keystore). Sem ele, o build de
// release cai na chave de debug: clonar e compilar continua funcionando, mas
// esse APK não serve para publicar. Ver docs/assinatura.md.
val propriedadesDaChave = Properties().apply {
    val arquivo = rootProject.file("key.properties")
    if (arquivo.exists()) {
        arquivo.reader(Charsets.UTF_8).use { load(it) }
    }
}
val temChaveDeRelease = propriedadesDaChave.getProperty("storeFile") != null

// A senha pode ficar fora do disco: sem `storePassword` no key.properties, vem
// da variável de ambiente OPENTUNER_SENHA_CHAVE. Keystore PKCS12 tem uma senha
// só, que vale para o arquivo e para a chave.
fun senhaDaChave(nome: String): String? =
    propriedadesDaChave.getProperty(nome) ?: System.getenv("OPENTUNER_SENHA_CHAVE")

android {
    namespace = "io.github.guilhermefeitosa66.opentuner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "io.github.guilhermefeitosa66.opentuner"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 7.0. O Flutter 3.38 já exige 24 por padrão; fixado aqui para
        // não mudar em silêncio numa atualização do Flutter.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (temChaveDeRelease) {
            create("release") {
                storeFile = file(propriedadesDaChave.getProperty("storeFile"))
                storePassword = senhaDaChave("storePassword")
                keyAlias = propriedadesDaChave.getProperty("keyAlias")
                keyPassword = senhaDaChave("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (temChaveDeRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Aviso visível quando um build de release sai com a chave de debug: esse APK
// instala, mas não atualiza o publicado, e o .aab não é aceito pela Play Store.
gradle.taskGraph.whenReady {
    val pediuRelease = allTasks.any { it.name.contains("Release") }
    if (pediuRelease && !temChaveDeRelease) {
        logger.warn(
            "AVISO: android/key.properties não encontrado. O build de release " +
                "está sendo assinado com a chave de DEBUG e não serve para " +
                "publicar. Ver docs/assinatura.md.",
        )
    }
}

flutter {
    source = "../.."
}
