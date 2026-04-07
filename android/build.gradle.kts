allprojects {
    repositories {
        google()
        maven { url = uri("https://mirrors.tuna.tsinghua.edu.cn/google/") }
        mavenCentral()
        maven { url = uri("https://mirrors.tuna.tsinghua.edu.cn/repo/") }
        maven { url = uri("https://mirrors.tuna.tsinghua.edu.cn/gradle-plugin/") }
        maven { url = uri("https://mirrors.tuna.tsinghua.edu.cn/flutter/download.flutter.io") }
        jcenter() // Just in case
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
