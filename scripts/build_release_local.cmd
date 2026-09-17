@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "GRADLE_USER_HOME=C:\Afghan in USA\.gradle-local"
set "PATH=%JAVA_HOME%\bin;%PATH%"
cd /d "C:\Afghan in USA\android"
call gradlew.bat assembleRelease --no-daemon --console=plain > "C:\Afghan in USA\build-release.log" 2>&1
echo %ERRORLEVEL% > "C:\Afghan in USA\build-release.exitcode"
