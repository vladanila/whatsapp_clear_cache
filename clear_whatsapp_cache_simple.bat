@echo off
setlocal EnableDelayedExpansion
title WhatsApp Cache Cleaner (Simple)

echo ======================================================================
echo                WhatsApp Cache Cleaner for PC (Simple)
echo ======================================================================
echo  Clears downloaded media and web caches while preserving your login.
echo ======================================================================
echo.

:: 1. Close WhatsApp if running
tasklist /fi "imagename eq WhatsApp*" 2>nul | find /i "WhatsApp" >nul
if %ERRORLEVEL% equ 0 (
    echo [!] WhatsApp is currently running.
    echo [*] Closing WhatsApp to unlock cache files...
    taskkill /F /IM WhatsApp*.exe /T >nul 2>&1
    timeout /t 2 /nobreak >nul
)

echo [*] Purging WhatsApp cache folders...
echo.

:: 2. Clean UWP / Microsoft Store WhatsApp Cache (Matches Stable, Beta and future packages)
for /d %%D in ("%LOCALAPPDATA%\Packages\*WhatsApp*") do (
    echo [Package] %%~nxD

    :: Media Transfers Cache (photos, videos, audio downloads)
    for /d %%S in ("%%D\LocalState\sessions\*") do (
        if exist "%%S\transfers" (
            echo   - Cleaning Media Transfers in %%~nxS...
            rd /s /q "%%S\transfers" >nul 2>&1
            mkdir "%%S\transfers" >nul 2>&1
        )
    )
    if exist "%%D\LocalState\shared\transfers" (
        echo   - Cleaning Shared Media Transfers...
        rd /s /q "%%D\LocalState\shared\transfers" >nul 2>&1
        mkdir "%%D\LocalState\shared\transfers" >nul 2>&1
    )

    :: WebView2 HTTP & Code Cache
    if exist "%%D\LocalCache\EBWebView\Default\Cache" (
        echo   - Cleaning HTTP Cache...
        rd /s /q "%%D\LocalCache\EBWebView\Default\Cache" >nul 2>&1
        mkdir "%%D\LocalCache\EBWebView\Default\Cache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\Default\Code Cache" (
        echo   - Cleaning Compiled Script Cache...
        rd /s /q "%%D\LocalCache\EBWebView\Default\Code Cache" >nul 2>&1
        mkdir "%%D\LocalCache\EBWebView\Default\Code Cache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\Default\GPUCache" (
        echo   - Cleaning GPU Cache...
        rd /s /q "%%D\LocalCache\EBWebView\Default\GPUCache" >nul 2>&1
        mkdir "%%D\LocalCache\EBWebView\Default\GPUCache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\Default\DawnGraphiteCache" (
        rd /s /q "%%D\LocalCache\EBWebView\Default\DawnGraphiteCache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\Default\DawnWebGPUCache" (
        rd /s /q "%%D\LocalCache\EBWebView\Default\DawnWebGPUCache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\Default\Service Worker\CacheStorage" (
        echo   - Cleaning Service Worker Cache...
        rd /s /q "%%D\LocalCache\EBWebView\Default\Service Worker\CacheStorage" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\Default\Service Worker\ScriptCache" (
        rd /s /q "%%D\LocalCache\EBWebView\Default\Service Worker\ScriptCache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\GrShaderCache" (
        echo   - Cleaning Shader Cache...
        rd /s /q "%%D\LocalCache\EBWebView\GrShaderCache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\ShaderCache" (
        rd /s /q "%%D\LocalCache\EBWebView\ShaderCache" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\Crashpad" (
        rd /s /q "%%D\LocalCache\EBWebView\Crashpad" >nul 2>&1
    )
    if exist "%%D\LocalCache\EBWebView\component_crx_cache" (
        rd /s /q "%%D\LocalCache\EBWebView\component_crx_cache" >nul 2>&1
    )
    if exist "%%D\LocalState\rotatedLogs" (
        echo   - Cleaning Rotated Logs...
        rd /s /q "%%D\LocalState\rotatedLogs" >nul 2>&1
        mkdir "%%D\LocalState\rotatedLogs" >nul 2>&1
    )
    if exist "%%D\AC\Temp" (
        rd /s /q "%%D\AC\Temp" >nul 2>&1
        mkdir "%%D\AC\Temp" >nul 2>&1
    )
    if exist "%%D\AC\INetCache" (
        rd /s /q "%%D\AC\INetCache" >nul 2>&1
        mkdir "%%D\AC\INetCache" >nul 2>&1
    )
    if exist "%%D\TempState" (
        rd /s /q "%%D\TempState" >nul 2>&1
        mkdir "%%D\TempState" >nul 2>&1
    )
)

:: 3. Clean Legacy Win32 / Electron WhatsApp Cache (if present)
if exist "%APPDATA%\WhatsApp\Cache" (
    echo [Legacy WhatsApp] Cleaning HTTP Cache...
    rd /s /q "%APPDATA%\WhatsApp\Cache" >nul 2>&1
    mkdir "%APPDATA%\WhatsApp\Cache" >nul 2>&1
)
if exist "%APPDATA%\WhatsApp\Code Cache" (
    echo [Legacy WhatsApp] Cleaning Script Cache...
    rd /s /q "%APPDATA%\WhatsApp\Code Cache" >nul 2>&1
    mkdir "%APPDATA%\WhatsApp\Code Cache" >nul 2>&1
)
if exist "%APPDATA%\WhatsApp\GPUCache" (
    echo [Legacy WhatsApp] Cleaning GPU Cache...
    rd /s /q "%APPDATA%\WhatsApp\GPUCache" >nul 2>&1
    mkdir "%APPDATA%\WhatsApp\GPUCache" >nul 2>&1
)
if exist "%APPDATA%\WhatsApp\Service Worker\CacheStorage" (
    rd /s /q "%APPDATA%\WhatsApp\Service Worker\CacheStorage" >nul 2>&1
)
if exist "%APPDATA%\WhatsApp\Service Worker\ScriptCache" (
    rd /s /q "%APPDATA%\WhatsApp\Service Worker\ScriptCache" >nul 2>&1
)
if exist "%APPDATA%\WhatsApp\logs" (
    echo [Legacy WhatsApp] Cleaning Logs...
    rd /s /q "%APPDATA%\WhatsApp\logs" >nul 2>&1
    mkdir "%APPDATA%\WhatsApp\logs" >nul 2>&1
)

echo.
echo ======================================================================
echo  WhatsApp cache cleanup complete!
echo  Your login session, chats, contacts, and settings were NOT touched.
echo ======================================================================
echo.

set /p RELAUNCH="Relaunch WhatsApp now? (Y/N) [Default: Y]: "
if /i not "%RELAUNCH%"=="n" (
    echo [*] Starting WhatsApp...
    start whatsapp:
)

exit /b 0
