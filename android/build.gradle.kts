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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val androidExt = project.extensions.getByName("android")
            try {
                val setNdkVersion = androidExt.javaClass.getMethod("setNdkVersion", String::class.java)
                setNdkVersion.invoke(androidExt, "27.0.12077973")
            } catch (e: Exception) {
                // Ignore if method not found
            }
        }
    }
}

