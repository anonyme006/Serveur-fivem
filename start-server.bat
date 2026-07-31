@echo off
REM Lance FXServer (Windows) avec ce dossier comme server-data
cd /d "%~dp0"
if not exist artifacts\FXServer.exe (
  echo Place les artifacts FiveM dans .\artifacts\
  echo https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
  exit /b 1
)
artifacts\FXServer.exe +exec server.cfg %*
