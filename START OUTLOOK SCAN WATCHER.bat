@echo off
title Horizon House - Outlook Scan Inbox Watcher
cd /d "%~dp0"
echo Starting Outlook Scan Inbox Watcher...
echo (Outlook must be installed on this PC with the scan mailbox added.)
echo Leave this window open. Close it or press Ctrl+C to stop.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0auto-doc-inbox-outlook.ps1"
pause
