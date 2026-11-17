@echo off
chcp 65001 >nul
title !!! DELETAR RANKING DO GUGA RUN !!!
color 4F
cd /d "%~dp0"
echo.
echo  ==========================================================
echo     ATENCAO!  ESTE ARQUIVO ZERA O RANKING DO GUGA RUN
echo  ==========================================================
echo.
echo   Todas as partidas e nomes do ranking vao sumir do jogo.
echo   O jogo sera fechado e aberto de novo com o ranking vazio.
echo.
echo   (Por seguranca, nada e apagado de verdade: o ranking antigo
echo    fica guardado na pasta  dados\ranking-apagado\  com data e hora.)
echo.
set "RESP="
set /p "RESP=  Para confirmar, digite APAGAR e aperte ENTER: "
if /I not "%RESP%"=="APAGAR" (
  color 2F
  echo.
  echo   Cancelado. Nada foi apagado.
  echo.
  pause
  exit /b
)

echo.
echo   Fechando o jogo...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*servidor.ps1*' -and $_.Name -like 'powershell*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1
taskkill /IM msedge.exe /F >nul 2>&1
taskkill /IM chrome.exe /F >nul 2>&1
timeout /t 3 /nobreak >nul

for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')"') do set "AGORA=%%i"
set "ARQ=dados\ranking-apagado\%AGORA%"
mkdir "%ARQ%" >nul 2>&1

rem Move (nao apaga) o ranking, as copias, os backups, o historico e a memoria do navegador
for %%f in (ranking.json ranking-copia.json historico-partidas.csv servidor.log) do if exist "dados\%%f" move /Y "dados\%%f" "%ARQ%\" >nul
if exist "dados\backups" move /Y "dados\backups" "%ARQ%\backups" >nul
if exist "dados\navegador" move /Y "dados\navegador" "%ARQ%\navegador" >nul

if exist "dados\ranking.json" (
  color 6F
  echo.
  echo   NAO consegui zerar: o ranking ainda esta aberto por algum programa.
  echo   Reinicie o computador e rode este arquivo de novo.
  echo.
  pause
  exit /b
)

color 2F
echo.
echo   Pronto! O ranking foi zerado.
echo   O ranking antigo ficou guardado em:  %ARQ%
echo.
echo   Abrindo o jogo de novo...
timeout /t 3 /nobreak >nul
start "" "%~dp0INICIAR GUGA RUN.bat"
exit /b
