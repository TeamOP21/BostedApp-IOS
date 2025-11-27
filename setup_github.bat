@echo off
echo Initialiserer Git repository...
git init

echo.
echo Tilføjer alle filer til Git...
git add .

echo.
echo Laver initial commit...
git commit -m "Initial commit - BostedApp iOS project"

echo.
echo Tilføjer GitHub remote...
git remote add origin https://github.com/TeamOP21/BostedApp-IOS.git

echo.
echo Skifter til main branch...
git branch -M main

echo.
echo Pusher til GitHub...
git push -u origin main

echo.
echo Færdig! BostedAppIOS er nu på GitHub.
pause
