import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://mvn.getui.com/nexus/content/repositories/releases/") }
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            if (namespace.isNullOrBlank()) {
                namespace = project.group.toString()
            }
            if (name.contains("umeng") && (compileSdk ?: 0) < 34) {
                compileSdk = 34
            }
        }
    }
    plugins.withId("org.jetbrains.kotlin.android") {
        // 这个插件同时带了空的 kt 模板和真正的 Java 实现，一起编译会类名冲突。
        if (name == "umeng_common_sdk") {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                exclude("**/*.kt")
            }
        }
    }
    // 旧插件会在自己的脚本里把 Java 写成 1.8。等它的脚本跑完再改成 17。
    // evaluationDependsOn 会让部分模块提前完成初始化，这时不能再调用 afterEvaluate。
    val subproject = this
    val alignJvm = {
        subproject.extensions.findByType(LibraryExtension::class.java)?.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
        subproject.tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
        subproject.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    if (state.executed) {
        alignJvm()
    } else {
        afterEvaluate { alignJvm() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
