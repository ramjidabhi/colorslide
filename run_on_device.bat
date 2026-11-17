@echo off
setlocal
echo ========================================================
echo  Deploying Unblock Puzzle: Slide Escape to Android Device
echo ========================================================

set "ADB=C:\Users\RAM\AppData\Local\Android\Sdk\platform-tools\adb.exe"
set "GODOT=C:\Users\RAM\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe"
set "JAVA_HOME=C:\Users\RAM\.jdks\jbr-21.0.11"
set "APK=build\UnblockPuzzleSlideEscape.apk"
set "PKG=com.colorslide.unblockescape"
set "ACTIVITY=com.godot.game.GodotAppLauncher"

echo [1/3] Checking connected Android devices...
"%ADB%" devices
if errorlevel 1 (
    echo Error: Failed to run adb. Make sure your phone is connected with USB Debugging enabled.
    pause
    exit /b 1
)

echo.
echo [2/3] Installing APK onto your device...
"%ADB%" install -r "%APK%"
if errorlevel 1 (
    echo Error: Installation failed. Please unlock your phone and accept any USB install prompts.
    pause
    exit /b 1
)

echo.
echo [3/4] Resetting app cache for fresh 200 levels...
"%ADB%" shell pm clear "%PKG%"

echo.
echo [4/4] Launching game on your device...
"%ADB%" shell am start -n "%PKG%/%ACTIVITY%"

echo.
echo ========================================================
echo  Game launched successfully on your Android phone!
echo ========================================================
pause
