@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
echo ==========================================
echo   حرب الملوك - تجهيز وبناء APK
echo ==========================================
where flutter >nul 2>nul
if errorlevel 1 (
  echo [خطأ] لم يتم العثور على Flutter في PATH.
  echo ثبّت Flutter SDK ثم أعد فتح نافذة الأوامر.
  pause
  exit /b 1
)
call flutter doctor
if errorlevel 1 goto failed
call flutter pub get
if errorlevel 1 goto failed
call flutter analyze
if errorlevel 1 goto failed
call flutter test
if errorlevel 1 goto failed
call flutter build apk --release
if errorlevel 1 goto failed
echo.
echo [نجاح] تم بناء APK:
echo %~dp0build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0
:failed
echo.
echo [فشل] راجع رسالة الخطأ أعلاه قبل المتابعة.
pause
exit /b 1
