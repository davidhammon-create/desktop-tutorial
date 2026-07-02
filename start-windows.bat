@echo off
cd /d "%~dp0"

echo AboWandler wird vorbereitet...

where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo Node.js wurde nicht gefunden.
  echo Bitte installiere es ^(kostenlos^) von https://nodejs.org ^(LTS-Version^) und starte dieses Programm danach erneut.
  pause
  exit /b 1
)

if not exist node_modules (
  echo Installiere Frontend-Komponenten ^(einmalig, kann ein paar Minuten dauern^)...
  call npm install
)

if not exist server\node_modules (
  echo Installiere Backend-Komponenten ^(einmalig^)...
  pushd server
  call npm install
  popd
)

if not exist dist (
  echo Baue die App ^(einmalig^)...
  call npm run build
)

set ABOWANDLER_STATIC_DIR=%cd%\dist
set PORT=8787
set HOST=127.0.0.1

echo Starte AboWandler...
pushd server
start "AboWandler-Server" /min cmd /c "node index.js"
popd

echo Warte, bis der Server bereit ist...
timeout /t 4 /nobreak >nul

start "" http://127.0.0.1:8787

echo.
echo AboWandler laeuft jetzt in deinem Browser.
echo Falls die Seite leer ist, warte kurz und laden sie neu ^(F5^).
echo Zum Beenden: das Fenster "AboWandler-Server" schliessen.
echo.
pause
