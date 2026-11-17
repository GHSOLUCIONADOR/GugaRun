@echo off
rem Cria um atalho na pasta Inicializar do Windows: o jogo abre sozinho quando o PC liga.
set "ALVO=%~dp0INICIAR GUGA RUN.bat"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Startup')+'\Guga Run.lnk');$s.TargetPath='%ALVO%';$s.WorkingDirectory='%~dp0';$s.WindowStyle=7;$s.Save()"
echo.
echo Pronto! O Guga Run vai abrir sozinho sempre que o computador ligar.
pause
