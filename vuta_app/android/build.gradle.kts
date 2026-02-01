import com.android.build.gradle.LibraryExtension
import org.gradle.kotlin.dsl.configure

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
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        val manifestFile = project.file("src/main/AndroidManifest.xml")
        if (!manifestFile.exists()) return@withId

        val manifestPackage =
            Regex("package\\s*=\\s*\"([^\"]+)\"")
                .find(manifestFile.readText())
                ?.groupValues
                ?.getOrNull(1)
                ?.trim()

        if (manifestPackage.isNullOrBlank()) return@withId

        extensions.configure<LibraryExtension> {
            val currentNamespace = runCatching { namespace }.getOrNull()
            if (currentNamespace.isNullOrBlank()) {
                namespace = manifestPackage
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
