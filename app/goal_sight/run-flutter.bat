@echo off
setlocal EnableExtensions

cd /d "%~dp0"
echo [1/3] Fetching Flutter packages...
call flutter pub get
if errorlevel 1 goto :error

echo [2/3] Detecting Android target...
set "ANDROID_DEVICE="
for /f "skip=1 tokens=1,2" %%A in ('"%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" devices') do (
  if /i "%%B"=="device" if not defined ANDROID_DEVICE set "ANDROID_DEVICE=%%A"
)

if not defined ANDROID_DEVICE (
  echo No Android device is currently available.
  echo Run an Android emulator or connect and authorize a phone, then try again.
  echo.
  flutter devices
  goto :error
)

echo [3/3] Launching Flutter on %ANDROID_DEVICE%...
call flutter run -d %ANDROID_DEVICE%
if errorlevel 1 goto :error

goto :end

:error
echo.
echo Flutter mobile launch did not complete successfully.
pause
exit /b 1

:end
echo.
echo Flutter mobile session ended.
pause