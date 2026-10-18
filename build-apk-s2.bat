@echo off
setlocal
cd /d "%~dp0"

echo Building Nousen S2 debug APK...
flutter build apk --debug --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true --dart-define=NOUSEN_CLOUD_FIRST_PROGRESS=true
set "BUILD_EXIT=%ERRORLEVEL%"

echo.
if "%BUILD_EXIT%"=="0" (
  echo Build succeeded. APK: build\app\outputs\flutter-apk\app-debug.apk
) else (
  echo Build failed with exit code %BUILD_EXIT%.
)
echo.
pause
exit /b %BUILD_EXIT%
