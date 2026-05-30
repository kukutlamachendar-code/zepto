@echo off
:: Prioritize the local flutter_engine folder inside the workspace root
set "FLUTTER_BIN=c:\Users\hp\Desktop\zepto\flutter_engine\bin"

:: Fallback check to other common default installation paths
if not exist "%FLUTTER_BIN%\flutter.bat" set "FLUTTER_BIN=C:\src\flutter\bin"
if not exist "%FLUTTER_BIN%\flutter.bat" set "FLUTTER_BIN=C:\flutter\bin"
if not exist "%FLUTTER_BIN%\flutter.bat" set "FLUTTER_BIN=C:\tools\flutter\bin"
if not exist "%FLUTTER_BIN%\flutter.bat" set "FLUTTER_BIN=%USERPROFILE%\flutter\bin"
if not exist "%FLUTTER_BIN%\flutter.bat" set "FLUTTER_BIN=%USERPROFILE%\src\flutter\bin"

echo ====================================================================
echo   Zepto Clone - Customer App Local Build Helper
echo ====================================================================
echo.
echo Checking for Flutter SDK in: "%FLUTTER_BIN%"

if not exist "%FLUTTER_BIN%\flutter.bat" (
    echo [ERROR] Flutter SDK (flutter.bat) was not found.
    echo.
    echo Searched path: "%FLUTTER_BIN%"
    echo.
    echo Troubleshooting:
    echo 1. Download the portable Flutter SDK from: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip
    echo 2. Extract it directly to: c:\Users\hp\Desktop\zepto\flutter_engine
    echo 3. Ensure the file "c:\Users\hp\Desktop\zepto\flutter_engine\bin\flutter.bat" exists.
    echo.
    pause
    exit /b 1
)

echo [OK] Found Flutter SDK at: "%FLUTTER_BIN%"
echo.

echo Step 1: Cleaning build directory...
call "%FLUTTER_BIN%\flutter.bat" clean
if %ERRORLEVEL% neq 0 (
    echo [WARNING] clean command returned errors.
)

echo.
echo Step 2: Fetching packages (pub get)...
call "%FLUTTER_BIN%\flutter.bat" pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] pub get failed. Check dependencies in pubspec.yaml.
    pause
    exit /b 1
)

echo.
echo Step 3: Compiling Debug APK...
call "%FLUTTER_BIN%\flutter.bat" build apk --debug
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Compilation failed. Check build logs above.
    pause
    exit /b 1
)

echo.
echo ====================================================================
echo   BUILD COMPLETED SUCCESSFULY!
echo   APK Path: customer_app\build\app\outputs\flutter-apk\app-debug.apk
echo ====================================================================
pause
