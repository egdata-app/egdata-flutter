import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
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

    // home_widget 0.8.x requests Glance with the floating version `1.+`.
    // Keep resolution on the API-36-compatible version used by this app;
    // otherwise Gradle can silently select a newer alpha requiring API 37.
    configurations.configureEach {
        resolutionStrategy.force(
            "androidx.glance:glance:1.2.0-alpha01",
            "androidx.glance:glance-appwidget:1.2.0-alpha01",
            "androidx.glance:glance-material3:1.2.0-alpha01",
        )
    }

    // home_widget 0.8.x declares JVM 1.8 while its current AndroidX Glance
    // dependencies contain Java 11 bytecode. Keep both compilers aligned with
    // the app's Java 17 toolchain so release builds can compile the plugin.
    if (project.name == "home_widget") {
        project.afterEvaluate {
            extensions.getByType<LibraryExtension>().compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            tasks.withType<KotlinCompile>().configureEach {
                compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
