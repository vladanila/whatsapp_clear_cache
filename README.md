# WhatsApp Cache Cleaner for Windows PC

A safe, fast, and lightweight tool to clear WhatsApp's cache and downloaded media build-up on Windows without logging you out of your account.

---

## Quick Start

1. Double-click **`clear_whatsapp_cache.bat`**.
2. If WhatsApp is currently open, the script will prompt you to close it to unlock cache files.
3. Select an option from the menu:
   - **`[1] Full Clean (Recommended)`**: Purges both downloaded media transfers and WebView2 application caches.
   - **`[2] Media Cache Only`**: Purges only downloaded media transfers (photos, videos, audio received/viewed).
   - **`[3] App & Web Cache Only`**: Purges WebView2 HTTP caches, compiled scripts, and GPU shader files only.
   - **`[4] Detailed Storage Breakdown`**: Shows a line-by-line inspection of cache folders and their sizes.
   - **`[5] Exit`**
4. Review the space reclaimed summary and optionally relaunch WhatsApp with a single keystroke.

---

## Safe Session Guarantee

**Will this log me out of WhatsApp?**  
**No.** The script strictly isolates and removes temporary cache files. The following critical files and directories are **NEVER** modified or deleted:

| Component | Path | Status |
| :--- | :--- | :--- |
| **Login Session & Auth** | `LocalState\session.db*` | 🛡️ **Protected** |
| **Local Storage & Sync** | `LocalState\genericStorage.db*` | 🛡️ **Protected** |
| **Contact Records** | `LocalState\contacts*.db*` | 🛡️ **Protected** |
| **Application Settings** | `Settings\settings.dat`, `nativeSettings.db*` | 🛡️ **Protected** |
| **Browser Storage & Cookies** | `EBWebView\Default\Local Storage`, `IndexedDB`, `Network` | 🛡️ **Protected** |

Your account remains paired, and your chat history, contacts, and settings stay completely intact.

---

## What Gets Cleaned?

### 1. Downloaded Media Transfers (`LocalState\sessions\*\transfers`)
When you view, open, or download media files in chats (photos, high-res pictures, videos, audio notes, documents), WhatsApp saves cached copies in `transfers`. Over weeks and months of heavy usage, this folder frequently expands to several gigabytes. Deleting this cache frees up this storage. *(If you ever need an old media file again in WhatsApp, you can re-download it from your chat).*

### 2. Edge WebView2 / Chromium Caches (`LocalCache\EBWebView\Default\*`)
- **`Cache\Cache_Data`**: Cached images, media segments, and network responses.
- **`Code Cache\js & wasm`**: Compiled JavaScript and WebAssembly byte-code cache.
- **`GPUCache` & `ShaderCache`**: Cached GPU shaders and rendering assets.
- **`Service Worker\CacheStorage` & `ScriptCache`**: Offline caching resources.
- **`Crashpad` & `rotatedLogs`**: Archived crash logs and text logs.
- **`AC\Temp` & `AC\INetCache`**: UWP container temporary files.

---

## Command-Line Usage (Automation & Shortcuts)

You can pass command-line arguments to `clear_whatsapp_cache.bat` for quick actions or scheduled tasks:

```cmd
:: Analyze cache sizes without deleting anything
clear_whatsapp_cache.bat /analyze

:: Run Full Clean automatically
clear_whatsapp_cache.bat /all

:: Run Media Clean only
clear_whatsapp_cache.bat /media

:: Run App & Web Cache clean only
clear_whatsapp_cache.bat /app

:: Silent mode (closes WhatsApp if open, runs Full Clean, exits without prompt)
clear_whatsapp_cache.bat /silent
```

### Automating with Windows Task Scheduler (e.g. Weekly Clean)
1. Open Windows **Task Scheduler** (`Win + R` -> `taskschd.msc`).
2. Click **Create Basic Task...** on the right.
3. Name it `WhatsApp Cache Cleaner`.
4. Trigger: Choose **Weekly** or **Monthly**.
5. Action: **Start a program**.
6. Program/script: Browse to `clear_whatsapp_cache.bat`.
7. Add arguments: `/silent`.
8. Finish! WhatsApp cache will now clean up automatically in the background.

---

## Files in this Repository

- **`clear_whatsapp_cache.bat`** *(Recommended)*: Interactive batch script with detailed space analysis, colorized output, safety checks, menu options, and command-line switches.
- **`clear_whatsapp_cache_simple.bat`**: Minimal pure CMD batch file using standard Windows command prompt syntax without PowerShell commands.
- **`README.md`**: Complete documentation and usage guide.
