@echo off
echo ========================================
echo BostedApp iOS Setup
echo ========================================
echo.

echo Creating directory structure...
if not exist "BostedApp\Views\Components" mkdir BostedApp\Views\Components
if not exist "BostedApp\ViewModels" mkdir BostedApp\ViewModels
if not exist "BostedApp\Models" mkdir BostedApp\Models
if not exist "BostedApp\API" mkdir BostedApp\API

echo.
echo Copying Swift source files...
copy "..\Swift\Sources\App\BostedApp.swift" "BostedApp\BostedApp.swift" >nul
copy "..\Swift\Sources\Views\*.swift" "BostedApp\Views\" >nul
copy "..\Swift\Sources\Views\Components\*.swift" "BostedApp\Views\Components\" >nul
copy "..\Swift\Sources\ViewModels\*.swift" "BostedApp\ViewModels\" >nul
copy "..\Swift\Sources\Models\*.swift" "BostedApp\Models\" >nul
copy "..\Swift\Sources\API\*.swift" "BostedApp\API\" >nul

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Open BostedApp.xcodeproj in Xcode
echo 2. Fix the issues listed in README.md
echo 3. Build and run (Cmd+R)
echo.
echo IMPORTANT: Read README.md for required code fixes!
echo.
pause
