@echo off
echo ======================================
echo  StudiumsPlan - Setup
echo ======================================
echo.

echo Checking Node.js installation...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js ist nicht installiert!
    echo Bitte installieren Sie Node.js von https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js gefunden: 
node --version
echo npm Version:
npm --version
echo.

echo Installing dependencies...
echo.
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process; npm install"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Installation fehlgeschlagen!
    pause
    exit /b 1
)

echo.
echo ======================================
echo  Installation erfolgreich!
echo ======================================
echo.
echo Starting development server...
echo Der Browser sollte automatisch auf http://localhost:5173 oeffnen
echo.
echo WICHTIG: Lassen Sie dieses Fenster geoeffnet!
echo Zum Beenden druecken Sie Strg+C
echo.

powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process; npm run dev"
