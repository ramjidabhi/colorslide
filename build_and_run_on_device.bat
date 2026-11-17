@echo off
setlocal
echo ========================================================
echo  Building and Running ColorSlide on Android Phone
echo ========================================================

set "ADB=C:\Users\RAM\AppData\Local\Android\Sdk\platform-tools\adb.exe"
set "GODOT=C:\Users\RAM\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe"
set "JAVA_HOME=C:\Users\RAM\.jdks\jbr-21.0.11"
set "APK=build\UnblockPuzzleSlideEscape.apk"
set "PKG=com.colorslide.unblockescape"
set "ACTIVITY=com.godot.game.GodotAppLauncher"

echo [1/4] Checking connected Android devices...
"%ADB%" devices

echo.
echo [2/4] Exporting debug APK with Godot...
"%GODOT%" --headless --path "%~dp0" --export-debug "Android" "%~dp0%APK%"
if errorlevel 1 (
    echo Error: Export failed.
    pause
    exit /b 1
)

echo.
echo [3/4] Installing APK to device via USB...
"%ADB%" install -r "%~dp0%APK%"
if errorlevel 1 (
    echo Error: Installation failed. Ensure device screen is unlocked.
    pause
    exit /b 1
)

echo.
echo [4/4] Launching game on device...
"%ADB%" shell am start -n "%PKG%/%ACTIVITY%"

echo.
echo ========================================================
echo  Game successfully compiled and launched on your device!
echo ========================================================
pause
