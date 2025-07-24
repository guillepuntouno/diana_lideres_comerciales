@echo off
echo Cleaning Flutter project...

REM Clean Flutter build cache
flutter clean

REM Delete lock files
del /f pubspec.lock 2>nul
del /f .flutter-plugins 2>nul
del /f .flutter-plugins-dependencies 2>nul

REM Delete build directories
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul

REM Get packages again
echo Getting packages...
flutter pub get

echo Project cleaned. You can now run: flutter run -d web-server --web-port=51052
pause