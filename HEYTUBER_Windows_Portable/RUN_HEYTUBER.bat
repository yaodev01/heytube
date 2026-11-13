@echo off
setlocal enabledelayedexpansion
title HEYTUBER Local PNGTuber Launcher
cd /d "%~dp0"

echo =====================================================================
echo    HEYTUBER / PIXELTUBER - Windows Local Launcher
echo    "Your Avatar. Your Voice. Your Stream."
echo =====================================================================
echo.
echo [1/2] Verifying application assets...

:: Priority 1: Check if standalone HEYTUBER.exe is present
if exist "HEYTUBER.exe" (
    echo [FOUND] Standalone HEYTUBER.exe detected. Launching native desktop engine...
    start "" "HEYTUBER.exe"
    exit /b 0
)

:: Priority 2: Check for SingleFile HTML or dist folder
set "HTML_TARGET="
if exist "HEYTUBER_SingleFile.html" (
    set "HTML_TARGET=HEYTUBER_SingleFile.html"
) else if exist "HEYTUBER.html" (
    set "HTML_TARGET=HEYTUBER.html"
) else if exist "dist\HEYTUBER_SingleFile.html" (
    set "HTML_TARGET=dist\HEYTUBER_SingleFile.html"
) else if exist "dist\index.html" (
    set "HTML_TARGET=dist\index.html"
) else if exist "index.html" (
    set "HTML_TARGET=index.html"
)

if "!HTML_TARGET!"=="" (
    echo [ERROR] No HEYTUBER application files found in this folder!
    echo Please make sure RUN_HEYTUBER.bat is placed in the HEYTUBER folder.
    echo.
    pause
    exit /b 1
)

echo [READY] Using HTML payload: !HTML_TARGET!
echo [2/2] Starting local web engine on 127.0.0.1:48999...
echo.
echo * Note: Keep this command prompt window open while streaming.
echo * Closing this window will stop the HEYTUBER engine.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$port = 48999; " ^
  "$listener = New-Object System.Net.HttpListener; " ^
  "$listener.Prefixes.Add(\"http://127.0.0.1:$port/\"); " ^
  "try { $listener.Start() } catch { $port = 49001; $listener = New-Object System.Net.HttpListener; $listener.Prefixes.Add(\"http://127.0.0.1:$port/\"); $listener.Start() }; " ^
  "$url = \"http://127.0.0.1:$port/\"; " ^
  "$edge = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue).'(Default)'; " ^
  "if (-not $edge -or -not (Test-Path $edge)) { $edge = \"msedge.exe\" }; " ^
  "try { Start-Process $edge -ArgumentList \"--app=$url --window-size=1200,780 --window-position=120,60 --user-data-dir=\`\"$env:TEMP\\HEYTUBER_App_v3\`\"\" } catch { Start-Process $url }; " ^
  "Write-Host '[ACTIVE] HEYTUBER is running on '$url -ForegroundColor Green; " ^
  "Write-Host '[OBS] Browser Source URL: http://127.0.0.1:'$port'/?mode=overlay' -ForegroundColor Cyan; " ^
  "$htmlFile = '!HTML_TARGET!'; " ^
  "while ($listener.IsListening) { " ^
  "  try { " ^
  "    $context = $listener.GetContext(); " ^
  "    $reqPath = $context.Request.Url.LocalPath.TrimStart('/'); " ^
  "    if ($reqPath -eq 'api/open-overlay') { " ^
  "      $popupUrl = \"http://127.0.0.1:$port/?mode=overlay&popup=1&transparent=true\"; " ^
  "      try { Start-Process $edge -ArgumentList \"--app=$popupUrl --new-window --window-size=480,520 --window-position=140,80 --user-data-dir=\`\"$env:TEMP\\HEYTUBER_Popup_v3\`\"\" } catch { Start-Process $popupUrl }; " ^
  "      $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes('{\"ok\":true,\"mode\":\"bat-edge-app\"}'); " ^
  "      $context.Response.ContentType = 'application/json; charset=utf-8'; " ^
  "      $context.Response.ContentLength64 = $jsonBytes.Length; " ^
  "      $context.Response.Headers.Add('Access-Control-Allow-Origin', '*'); " ^
  "      $context.Response.OutputStream.Write($jsonBytes, 0, $jsonBytes.Length); " ^
  "      $context.Response.Close(); " ^
  "      continue; " ^
  "    }; " ^
  "    if ([string]::IsNullOrEmpty($reqPath) -or $reqPath -eq '/' -or $reqPath.EndsWith('.html')) { " ^
  "      $filePath = $htmlFile; " ^
  "    } else { " ^
  "      $filePath = $reqPath; " ^
  "      if (-not (Test-Path $filePath)) { $filePath = Join-Path 'dist' $reqPath }; " ^
  "      if (-not (Test-Path $filePath)) { $filePath = $htmlFile }; " ^
  "    }; " ^
  "    $bytes = [System.IO.File]::ReadAllBytes($filePath); " ^
  "    $ext = [System.IO.Path]::GetExtension($filePath).ToLower(); " ^
  "    $mime = 'application/octet-stream'; " ^
  "    switch ($ext) { " ^
  "      '.html' { $mime = 'text/html; charset=utf-8' } " ^
  "      '.js'   { $mime = 'application/javascript; charset=utf-8' } " ^
  "      '.css'  { $mime = 'text/css; charset=utf-8' } " ^
  "      '.png'  { $mime = 'image/png' } " ^
  "      '.jpg'  { $mime = 'image/jpeg' } " ^
  "      '.ico'  { $mime = 'image/x-icon' } " ^
  "      '.svg'  { $mime = 'image/svg+xml' } " ^
  "      '.json' { $mime = 'application/json' } " ^
  "    }; " ^
  "    $context.Response.ContentType = $mime; " ^
  "    $context.Response.ContentLength64 = $bytes.Length; " ^
  "    $context.Response.Headers.Add('Access-Control-Allow-Origin', '*'); " ^
  "    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length); " ^
  "    $context.Response.Close(); " ^
  "  } catch { " ^
  "    break; " ^
  "  } " ^
  "}"
