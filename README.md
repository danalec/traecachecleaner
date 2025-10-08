# Trae Cache & Cookies Cleaner

PowerShell script to clean Trae application cookies and optional storages/caches under:
- %APPDATA%\Trae
- %LOCALAPPDATA%\Trae

It helps resolve issues caused by corrupted cookies or site data (e.g., Figma login/session problems in Trae solo mode).

## Common problem this script addresses

When logging into Figma inside Trae (solo mode), accepting the cookie banner ("Allow all cookies") may lead to a broken session and show a black page with the message "Service is unavailable." This usually happens due to corrupted cookies or mismatched site data stored by Trae’s embedded browser (cookies, Local Storage, IndexedDB, or cache partitions).

Illustration:

![Figma login cookie accept leading to "Service is unavailable"](assets/figma-login-issue.png)

### How the script helps
- Removes cookie files that can keep an inconsistent/broken login state.
- Optionally deletes Local Storage and IndexedDB entries that may conflict with new sessions.
- Optionally clears caches and partition data used by the embedded browser.

### Recommended fix steps
1. Close Trae completely.
2. Run a full cleanup:
   ```powershell
   ./Clear-TraeCookies.ps1 -All
   ```
3. Restart Trae and try logging into Figma again. Accept cookies when prompted.
4. If the issue persists, run again with `-Backup -All` to keep a backup, then retry. You can also share the backup for troubleshooting.

## Features
- Stop Trae processes to avoid locked files
- Remove cookie files (Cookies and Cookies-journal) across all profiles
- Optional cleanup of Local Storage, IndexedDB, Session Storage, and various caches (GPUCache, Code Cache, blob_storage, Service Worker, Cache)
- Optional backup of all files/directories before removal
- Dry‑run mode to preview actions

## Requirements
- Windows with PowerShell 5.1+ or PowerShell 7+

## Usage
Open PowerShell in the project folder:

```powershell
Set-Location "c:\Users\danalec\Documents\src\traecachecleaner"
```

Run one of the following:

```powershell
# Clean cookies only
./Clear-TraeCookies.ps1

# Backup cookies before deleting
./Clear-TraeCookies.ps1 -Backup

# Clean everything (cookies + storages + caches)
./Clear-TraeCookies.ps1 -All

# Dry-run to preview what would be deleted
./Clear-TraeCookies.ps1 -WhatIf
```

If script execution is blocked, run temporarily with bypass:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; ./Clear-TraeCookies.ps1 -All
```

## Notes
- After cleanup, restart Trae and sign in again if needed.
- Using `-All` will delete site data and caches; sessions will be cleared.
- Backups are stored in `%TEMP%/TraeCookiesBackup_yyyyMMdd_HHmmss/` unless you provide a custom path.

## What gets cleaned
- Cookies: `Cookies`, `Cookies-journal`
- Storages (when enabled): `Local Storage`, `IndexedDB`, `Session Storage`
- Caches (when enabled): `GPUCache`, `Code Cache`, `blob_storage`, `Service Worker`, `Cache`, `DawnCache`

## Disclaimer
This script deletes application data. Use at your own risk. Consider using `-Backup` first so you can restore if needed.
