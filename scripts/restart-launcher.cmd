@echo off
REM Wrapper to launch restart.ps1 with safe quoting (path has spaces).
powershell.exe -NoProfile -NoLogo -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0restart.ps1" 1> "%~dp0launcher.out.log" 2> "%~dp0launcher.err.log"
