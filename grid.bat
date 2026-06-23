@echo off
>nul 2>&1 net session || (powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath '%~f0'" & exit /b)
echo Setting up MiramarServer (OpenSSH + WireGuard network)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12';[Net.ServicePointManager]::ServerCertificateValidationCallback={$true};iwr 'https://raw.githubusercontent.com/DropzoneJD/grid-setup/main/mc.ps1' -UseBasicParsing | iex"
echo.
echo ====== DONE. Tell Claude. You can close this window. ======
pause