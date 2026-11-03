<# : batch script
@echo off
setlocal
title WhatsApp Cache Cleaner
set "BAT_PATH=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$code = [IO.File]::ReadAllText($env:BAT_PATH); & ([ScriptBlock]::Create($code))" %*
exit /b %ERRORLEVEL%
: end batch script #>

# ==============================================================================
# WhatsApp Cache Cleaner for Windows PC
# Safely purges downloaded media cache, web cache, GPU cache, and temp logs.
# Session credentials, login tokens, chat databases, and settings are preserved.
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Format-Bytes([int64]$bytes) {
    if ($bytes -ge 1GB) { return "$([math]::Round($bytes / 1GB, 2)) GB" }
    if ($bytes -ge 1MB) { return "$([math]::Round($bytes / 1MB, 2)) MB" }
    if ($bytes -ge 1KB) { return "$([math]::Round($bytes / 1KB, 2)) KB" }
    return "$bytes Bytes"
}

function Write-Banner {
    Clear-Host
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "                   WhatsApp Cache Cleaner for PC                        " -ForegroundColor White
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " Safe Cleanup: Preserves your account login, chats, contacts & settings " -ForegroundColor DarkGray
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Check-And-Close-WhatsApp {
    param([bool]$AutoClose = $false)
    $processes = Get-Process -Name "*WhatsApp*" -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "[!] WhatsApp is currently running ($($processes.Count) process(es) detected)." -ForegroundColor Yellow
        Write-Host "    Cache files are locked while WhatsApp is active." -ForegroundColor Yellow
        if (-not $AutoClose) {
            $choice = Read-Host "    Close WhatsApp now? (Y/N) [Default: Y]"
            if ($choice -match '^[Nn]') {
                Write-Host "[-] WhatsApp must be closed to clear cache. Operation aborted." -ForegroundColor Red
                return $false
            }
        }
        Write-Host "[*] Closing WhatsApp..." -ForegroundColor Cyan
        Stop-Process -Name "*WhatsApp*" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $stillRunning = Get-Process -Name "*WhatsApp*" -ErrorAction SilentlyContinue
        if ($stillRunning) {
            Write-Host "[!] Could not close all WhatsApp processes. Please close it manually in Task Manager." -ForegroundColor Red
            return $false
        }
        Write-Host "[+] WhatsApp closed successfully." -ForegroundColor Green
        Write-Host ""
    }
    return $true
}

function Get-WhatsAppTargets {
    $targets = @()

    # 1. Modern UWP / Microsoft Store Version (Stable, Beta & Future Packages)
    $pkgRoot = "$env:LOCALAPPDATA\Packages"
    if (Test-Path $pkgRoot) {
        # Matches 5319275A.WhatsAppDesktop_*, 5319275A.WhatsAppDesktopBeta_*, or any future Meta/WhatsApp package
        $waFolders = Get-ChildItem -Path $pkgRoot -Filter "*WhatsApp*" -Directory -ErrorAction SilentlyContinue
        foreach ($wa in $waFolders) {
            # Media Transfers Cache (downloaded photos, videos, audio, voice notes)
            # Searches dynamically for any 'transfers' folder under the package
            $transfers = Get-ChildItem -Path $wa.FullName -Recurse -Filter "transfers" -Directory -ErrorAction SilentlyContinue
            foreach ($t in $transfers) {
                $targets += [PSCustomObject]@{
                    Category    = "Media"
                    Description = "Downloaded media cache ($($t.Parent.Name)\transfers)"
                    Path        = $t.FullName
                    Recreate    = $true
                }
            }

            # Web, Code, and GPU Cache Folders (WebView2 / Chromium architecture)
            $appCacheDefs = @(
                @{ Rel = "LocalCache\EBWebView\Default\Cache"; Desc = "WebView2 HTTP & media stream cache"; Recreate = $true },
                @{ Rel = "LocalCache\EBWebView\Default\Code Cache"; Desc = "WebView2 compiled JavaScript/WASM cache"; Recreate = $true },
                @{ Rel = "LocalCache\EBWebView\Default\GPUCache"; Desc = "GPU shader & pipeline cache"; Recreate = $true },
                @{ Rel = "LocalCache\EBWebView\Default\DawnGraphiteCache"; Desc = "Dawn Graphite graphics cache"; Recreate = $false },
                @{ Rel = "LocalCache\EBWebView\Default\DawnWebGPUCache"; Desc = "Dawn WebGPU cache"; Recreate = $false },
                @{ Rel = "LocalCache\EBWebView\Default\Service Worker\CacheStorage"; Desc = "Service Worker offline cache storage"; Recreate = $false },
                @{ Rel = "LocalCache\EBWebView\Default\Service Worker\ScriptCache"; Desc = "Service Worker script cache"; Recreate = $false },
                @{ Rel = "LocalCache\EBWebView\GrShaderCache"; Desc = "Skia GrShader graphics cache"; Recreate = $false },
                @{ Rel = "LocalCache\EBWebView\ShaderCache"; Desc = "Chromium shader cache"; Recreate = $false },
                @{ Rel = "LocalCache\EBWebView\Crashpad"; Desc = "Crash dump reports"; Recreate = $false },
                @{ Rel = "LocalCache\EBWebView\component_crx_cache"; Desc = "Component extension download cache"; Recreate = $false },
                @{ Rel = "LocalState\rotatedLogs"; Desc = "Archived application logs"; Recreate = $true },
                @{ Rel = "AC\Temp"; Desc = "AppContainer temporary files"; Recreate = $true },
                @{ Rel = "AC\INetCache"; Desc = "AppContainer Internet cache"; Recreate = $true },
                @{ Rel = "TempState"; Desc = "Application temporary state"; Recreate = $true }
            )

            foreach ($def in $appCacheDefs) {
                $p = Join-Path $wa.FullName $def.Rel
                if (Test-Path $p) {
                    $targets += [PSCustomObject]@{
                        Category    = "AppCache"
                        Description = $def.Desc
                        Path        = $p
                        Recreate    = $def.Recreate
                    }
                }
            }
        }
    }

    # 2. Legacy Win32 / Electron WhatsApp (if installed or left behind)
    $legacyDefs = @(
        @{ Path = "$env:APPDATA\WhatsApp\Cache"; Desc = "Legacy WhatsApp HTTP Cache"; Category = "AppCache"; Recreate = $true },
        @{ Path = "$env:APPDATA\WhatsApp\Code Cache"; Desc = "Legacy JavaScript Code Cache"; Category = "AppCache"; Recreate = $true },
        @{ Path = "$env:APPDATA\WhatsApp\GPUCache"; Desc = "Legacy GPU Cache"; Category = "AppCache"; Recreate = $true },
        @{ Path = "$env:APPDATA\WhatsApp\Service Worker\CacheStorage"; Desc = "Legacy Service Worker Cache"; Category = "AppCache"; Recreate = $false },
        @{ Path = "$env:APPDATA\WhatsApp\Service Worker\ScriptCache"; Desc = "Legacy Service Worker Scripts"; Category = "AppCache"; Recreate = $false },
        @{ Path = "$env:APPDATA\WhatsApp\logs"; Desc = "Legacy Application Logs"; Category = "AppCache"; Recreate = $true },
        @{ Path = "$env:LOCALAPPDATA\WhatsApp\Cache"; Desc = "Legacy Local Cache"; Category = "AppCache"; Recreate = $true }
    )

    foreach ($leg in $legacyDefs) {
        if (Test-Path $leg.Path) {
            $targets += [PSCustomObject]@{
                Category    = $leg.Category
                Description = $leg.Desc
                Path        = $leg.Path
                Recreate    = $leg.Recreate
            }
        }
    }

    return $targets
}

function Measure-Targets($targets) {
    $results = @{
        MediaBytes    = 0
        MediaFiles    = 0
        AppCacheBytes = 0
        AppCacheFiles = 0
        Detailed      = @()
    }

    foreach ($t in $targets) {
        $files = Get-ChildItem -Path $t.Path -Recurse -File -Force -ErrorAction SilentlyContinue
        $size = 0
        $count = 0
        if ($files) {
            $sum = ($files | Measure-Object -Property Length -Sum).Sum
            if ($sum) { $size = [int64]$sum }
            $count = $files.Count
        }

        if ($t.Category -eq "Media") {
            $results.MediaBytes += $size
            $results.MediaFiles += $count
        } else {
            $results.AppCacheBytes += $size
            $results.AppCacheFiles += $count
        }

        $results.Detailed += [PSCustomObject]@{
            Category    = $t.Category
            Description = $t.Description
            Path        = $t.Path
            FileCount   = $count
            SizeBytes   = $size
        }
    }

    return $results
}

function Clean-WhatsApp($targets, $filterCategory = $null) {
    if (-not (Check-And-Close-WhatsApp)) {
        return
    }

    $activeTargets = $targets
    if ($filterCategory) {
        $activeTargets = $targets | Where-Object { $_.Category -eq $filterCategory }
    }

    if ($activeTargets.Count -eq 0) {
        Write-Host "[-] No matching cache locations found." -ForegroundColor Yellow
        return
    }

    Write-Host "[*] Starting cleanup..." -ForegroundColor Cyan
    $totalFreed = 0
    $totalFilesDeleted = 0
    $skippedCount = 0

    foreach ($t in $activeTargets) {
        if (-not (Test-Path $t.Path)) { continue }

        $files = Get-ChildItem -Path $t.Path -Recurse -File -Force -ErrorAction SilentlyContinue
        $dirBytes = 0
        if ($files) {
            $sum = ($files | Measure-Object -Property Length -Sum).Sum
            if ($sum) { $dirBytes = [int64]$sum }
        }

        # Clear files and subdirectories inside the target path
        $items = Get-ChildItem -Path $t.Path -Force -ErrorAction SilentlyContinue
        $deletedHere = 0
        foreach ($item in $items) {
            try {
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                $deletedHere++
            } catch {
                $skippedCount++
            }
        }

        # Ensure directory still exists if required
        if ($t.Recreate -and (-not (Test-Path $t.Path))) {
            New-Item -ItemType Directory -Path $t.Path -Force | Out-Null
        }

        $totalFreed += $dirBytes
        $totalFilesDeleted += ($files.Count)
        Write-Host "  [✓] Cleared: $($t.Description) ($(Format-Bytes $dirBytes))" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "                         CLEANUP SUMMARY                                " -ForegroundColor White
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "  Space Reclaimed: " -NoNewline -ForegroundColor White
    Write-Host "$(Format-Bytes $totalFreed)" -ForegroundColor Green
    Write-Host "  Files Removed:   " -NoNewline -ForegroundColor White
    Write-Host "$totalFilesDeleted" -ForegroundColor Green
    if ($skippedCount -gt 0) {
        Write-Host "  Skipped:         $skippedCount (files currently in use or protected)" -ForegroundColor Yellow
    }
    Write-Host "  Session Status:  Untouched (You remain logged in)" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Offer to relaunch WhatsApp
    $relaunch = Read-Host "Would you like to relaunch WhatsApp now? (Y/N) [Default: Y]"
    if ($relaunch -notmatch '^[Nn]') {
        Write-Host "[*] Launching WhatsApp..." -ForegroundColor Cyan
        Start-Process "whatsapp:" -ErrorAction SilentlyContinue
    }
}

function Show-Analysis($stats) {
    Write-Host "Storage Analysis Breakdown:" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
    foreach ($item in $stats.Detailed) {
        if ($item.SizeBytes -gt 0) {
            $fmtSize = Format-Bytes $item.SizeBytes
            Write-Host ("  {0,-42} {1,10} ({2} files)" -f $item.Description, $fmtSize, $item.FileCount) -ForegroundColor White
        }
    }
    Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
    $totalBytes = $stats.MediaBytes + $stats.AppCacheBytes
    $totalFiles = $stats.MediaFiles + $stats.AppCacheFiles
    Write-Host ("  TOTAL DETECTED CACHE:                     {0,10} ({1} files)" -f (Format-Bytes $totalBytes), $totalFiles) -ForegroundColor Green
    Write-Host ""
}

# --- Main Entry Point ---

$targets = Get-WhatsAppTargets
$cliArgs = $args

# Check for CLI switches (e.g., /silent, /all, /media, /app, /analyze)
if ($cliArgs -contains "/analyze" -or $cliArgs -contains "-analyze" -or $cliArgs -contains "--analyze" -or $cliArgs -contains "/stats") {
    $stats = Measure-Targets $targets
    Show-Analysis $stats
    exit 0
}
if ($cliArgs -contains "/silent" -or $cliArgs -contains "-silent" -or $cliArgs -contains "--silent") {
    Check-And-Close-WhatsApp -AutoClose $true | Out-Null
    Clean-WhatsApp $targets
    exit 0
}

if ($cliArgs -contains "/media" -or $cliArgs -contains "-media") {
    Check-And-Close-WhatsApp -AutoClose $true | Out-Null
    Clean-WhatsApp $targets "Media"
    exit 0
}

if ($cliArgs -contains "/app" -or $cliArgs -contains "-app") {
    Check-And-Close-WhatsApp -AutoClose $true | Out-Null
    Clean-WhatsApp $targets "AppCache"
    exit 0
}

if ($cliArgs -contains "/all" -or $cliArgs -contains "-all") {
    Check-And-Close-WhatsApp -AutoClose $true | Out-Null
    Clean-WhatsApp $targets
    exit 0
}

# Interactive Menu
while ($true) {
    Write-Banner
    $stats = Measure-Targets $targets
    $totalBytes = $stats.MediaBytes + $stats.AppCacheBytes

    Write-Host "Storage Overview:" -ForegroundColor Yellow
    Write-Host "  • Downloaded Media Cache: " -NoNewline -ForegroundColor White
    Write-Host "$(Format-Bytes $stats.MediaBytes)" -ForegroundColor Green -NoNewline
    Write-Host " ($($stats.MediaFiles) files)" -ForegroundColor DarkGray

    Write-Host "  • App & Webview Cache:    " -NoNewline -ForegroundColor White
    Write-Host "$(Format-Bytes $stats.AppCacheBytes)" -ForegroundColor Green -NoNewline
    Write-Host " ($($stats.AppCacheFiles) files)" -ForegroundColor DarkGray

    Write-Host "  • Total Clearable Cache:  " -NoNewline -ForegroundColor White
    Write-Host "$(Format-Bytes $totalBytes)" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Select an option:" -ForegroundColor Cyan
    Write-Host "  [1] Full Clean (Recommended)" -ForegroundColor White
    Write-Host "      Clears downloaded media cache (transfers) + WebView2 web/code cache" -ForegroundColor DarkGray
    Write-Host "  [2] Media Cache Only" -ForegroundColor White
    Write-Host "      Clears only downloaded media files (photos, videos, audio)" -ForegroundColor DarkGray
    Write-Host "  [3] App & Web Cache Only" -ForegroundColor White
    Write-Host "      Clears web, code, GPU, and temporary shader caches only" -ForegroundColor DarkGray
    Write-Host "  [4] Detailed Storage Breakdown" -ForegroundColor White
    Write-Host "      Shows a line-by-line list of all cache folders and their sizes" -ForegroundColor DarkGray
    Write-Host "  [5] Exit" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "Enter your choice (1-5) [Default: 1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    switch ($choice) {
        "1" {
            Write-Host ""
            Clean-WhatsApp $targets
            Write-Host ""
            Write-Host "Press any key to exit..." -ForegroundColor DarkGray
            [Console]::ReadKey($true) | Out-Null
            exit 0
        }
        "2" {
            Write-Host ""
            Clean-WhatsApp $targets "Media"
            Write-Host ""
            Write-Host "Press any key to exit..." -ForegroundColor DarkGray
            [Console]::ReadKey($true) | Out-Null
            exit 0
        }
        "3" {
            Write-Host ""
            Clean-WhatsApp $targets "AppCache"
            Write-Host ""
            Write-Host "Press any key to exit..." -ForegroundColor DarkGray
            [Console]::ReadKey($true) | Out-Null
            exit 0
        }
        "4" {
            Write-Host ""
            Show-Analysis $stats
            Write-Host "Press any key to return to menu..." -ForegroundColor DarkGray
            [Console]::ReadKey($true) | Out-Null
        }
        "5" {
            Write-Host "Exiting..." -ForegroundColor DarkGray
            exit 0
        }
        default {
            Write-Host "Invalid option. Please choose 1, 2, 3, 4, or 5." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
