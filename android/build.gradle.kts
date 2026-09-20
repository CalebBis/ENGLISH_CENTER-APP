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
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        if (project.name == "qr_code_scanner") {
            kotlinOptions {
                jvmTarget = "1.8"
            }
        }
    }
}
subprojects {
    afterEvaluate {
        if (project.name == "qr_code_scanner") {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    androidExt.javaClass.getMethod("setNamespace", String::class.java).invoke(androidExt, "net.touchcapture.qr.flutterqr")
                } catch (e: Exception) {
                    println("Failed to set namespace on qr_code_scanner: ${e.message}")
                }
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
