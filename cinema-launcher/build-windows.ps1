$ErrorActionPreference = 'Stop'
$taskWorkspace = Split-Path $PSScriptRoot -Parent
$taskJdkDir = $env:JAVA_HOME
if (-not $taskJdkDir -or -not (Test-Path (Join-Path $taskJdkDir 'bin\javac.exe'))) {
    $taskJdkDir = (Get-ChildItem (Join-Path $taskWorkspace 'tools\jdk17') -Directory | Select-Object -First 1).FullName
}
$taskSdkRoot = $env:ANDROID_HOME
if (-not $taskSdkRoot) { $taskSdkRoot = $env:ANDROID_SDK_ROOT }
if ($taskSdkRoot -and (Test-Path (Join-Path $taskSdkRoot 'platforms\android-25\android.jar'))) {
    $taskAndroidJar = Join-Path $taskSdkRoot 'platforms\android-25\android.jar'
    $taskBuildTools = (Get-ChildItem (Join-Path $taskSdkRoot 'build-tools') -Recurse -Filter aapt2.exe | Sort-Object FullName | Select-Object -Last 1).DirectoryName
} else {
    $taskBuildTools = (Get-ChildItem (Join-Path $taskWorkspace 'tools\android-sdk\buildtools34') -Recurse -Filter aapt2.exe | Select-Object -First 1).DirectoryName
    $taskAndroidJar = (Get-ChildItem (Join-Path $taskWorkspace 'tools\android-sdk\platform25') -Recurse -Filter android.jar | Select-Object -First 1).FullName
}
$env:JAVA_HOME = $taskJdkDir
$env:PATH = (Join-Path $taskJdkDir 'bin') + ';' + $env:PATH
$taskOutDir = Join-Path $PSScriptRoot 'build'
$taskWorkDir = Join-Path $taskOutDir ('compile-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $taskOutDir,$taskWorkDir,(Join-Path $taskWorkDir 'gen'),(Join-Path $taskWorkDir 'classes') | Out-Null
function Run-Checked([string]$Executable,[string[]]$Arguments) {
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $Executable (exit $LASTEXITCODE)" }
}
$taskKey = Join-Path $taskOutDir 'cinema.keystore'
if (-not (Test-Path $taskKey)) {
    Run-Checked (Join-Path $taskJdkDir 'bin\keytool.exe') @('-genkeypair','-keystore',$taskKey,'-alias','home','-keyalg','RSA','-keysize','2048','-validity','10000','-storepass','cinemahome','-keypass','cinemahome','-dname','CN=Cinema home local')
}
$taskResources = Join-Path $taskWorkDir 'res.zip'
Run-Checked (Join-Path $taskBuildTools 'aapt2.exe') @('compile','--dir',(Join-Path $PSScriptRoot 'res'),'-o',$taskResources)
$taskRawApk = Join-Path $taskWorkDir 'app.apk'
Run-Checked (Join-Path $taskBuildTools 'aapt2.exe') @('link','-I',$taskAndroidJar,'--manifest',(Join-Path $PSScriptRoot 'AndroidManifest.xml'),$taskResources,'--min-sdk-version','25','--target-sdk-version','28','--version-code','3','--version-name','1.2','--java',(Join-Path $taskWorkDir 'gen'),'-o',$taskRawApk)
$taskSources = Get-ChildItem (Join-Path $PSScriptRoot 'src'),(Join-Path $taskWorkDir 'gen') -Recurse -Filter *.java | ForEach-Object FullName
Run-Checked (Join-Path $taskJdkDir 'bin\javac.exe') (@('--release','8','-Xlint:all','-Xlint:-options','-Werror','-encoding','UTF-8','-classpath',$taskAndroidJar,'-d',(Join-Path $taskWorkDir 'classes')) + $taskSources)
$taskClassesJar = Join-Path $taskWorkDir 'classes.jar'
Run-Checked (Join-Path $taskJdkDir 'bin\jar.exe') @('--create','--file',$taskClassesJar,'-C',(Join-Path $taskWorkDir 'classes'),'.')
Run-Checked (Join-Path $taskJdkDir 'bin\java.exe') @('-cp',(Join-Path $taskBuildTools 'lib\d8.jar'),'com.android.tools.r8.D8','--release','--min-api','25','--lib',$taskAndroidJar,'--output',$taskWorkDir,$taskClassesJar)
Run-Checked (Join-Path $taskJdkDir 'bin\jar.exe') @('--update','--file',$taskRawApk,'-C',$taskWorkDir,'classes.dex')
$taskAligned = Join-Path $taskWorkDir 'aligned.apk'
Run-Checked (Join-Path $taskBuildTools 'zipalign.exe') @('-f','-p','4',$taskRawApk,$taskAligned)
$taskFinal = Join-Path $taskOutDir 'cinema-home-preview.apk'
Run-Checked (Join-Path $taskJdkDir 'bin\java.exe') @('-jar',(Join-Path $taskBuildTools 'lib\apksigner.jar'),'sign','--ks',$taskKey,'--ks-pass','pass:cinemahome','--key-pass','pass:cinemahome','--out',$taskFinal,$taskAligned)
Run-Checked (Join-Path $taskJdkDir 'bin\java.exe') @('-jar',(Join-Path $taskBuildTools 'lib\apksigner.jar'),'verify','--verbose',$taskFinal)
Run-Checked (Join-Path $taskBuildTools 'aapt2.exe') @('dump','badging',$taskFinal)
Get-FileHash $taskFinal -Algorithm SHA256
