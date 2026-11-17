@echo off
rem Guga Run - abre o jogo em tela cheia, sem internet
cd /d "%~dp0"
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0servidor.ps1"
timeout /t 3 /nobreak >nul
set "URL=http://localhost:8787/"
set "PERFIL=%~dp0dados\navegador"
set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" set "EDGE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if exist "%EDGE%" (
  start "" "%EDGE%" --kiosk "%URL%" --edge-kiosk-type=fullscreen --no-first-run --disable-features=Translate --user-data-dir="%PERFIL%"
  exit /b
)
set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if exist "%CHROME%" (
  start "" "%CHROME%" --kiosk "%URL%" --no-first-run --user-data-dir="%PERFIL%"
  exit /b
)
start "" "%URL%"
