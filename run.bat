@echo off
echo Jaikisan Card - Digital Payment App
echo ===================================
echo.

echo Checking Flutter environment...
flutter doctor --android-licenses > nul 2>&1

echo Installing dependencies...
flutter pub get

echo Generating code for Hive models...
dart run build_runner build

echo.
echo Starting the app...
echo Note: Make sure you have an Android device connected or emulator running
echo.

flutter run


