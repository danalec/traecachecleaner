# Clear-TraeCookies.ps1
#
# Limpa cookies do aplicativo Trae nas pastas %APPDATA%\Trae e %LOCALAPPDATA%\Trae.
#
# Uso:
#   1) Abra o PowerShell na pasta deste script.
#   2) Executar:
#        .\Clear-TraeCookies.ps1                 # limpa somente cookies
#        .\Clear-TraeCookies.ps1 -Backup         # faz backup dos cookies antes de apagar
#        .\Clear-TraeCookies.ps1 -All            # limpa cookies, storages (Local Storage/IndexedDB) e caches
#        .\Clear-TraeCookies.ps1 -WhatIf         # mostra o que seria apagado sem apagar
#
# Observações:
# - O script tenta parar processos do Trae para evitar arquivos bloqueados.
# - Procura e exclui arquivos "Cookies" e "Cookies-journal" em todos os perfis
#   (inclui caminhos como Default\Network\Cookies e Partitions).

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Backup,
    [string]$BackupDir = (Join-Path $env:TEMP ("TraeCookiesBackup_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))),
    [switch]$IncludeStorage,
    [switch]$IncludeCaches,
    [switch]$All
)

if ($All) { $IncludeStorage = $true; $IncludeCaches = $true }

function Stop-TraeProcesses {
    Write-Host "Verificando processos do Trae..." -ForegroundColor Cyan
    try {
        $procs = Get-Process -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like 'Trae*' -or ($_.Path -and ($_.Path -match '\\Trae\\')) }
        if ($procs) {
            foreach ($p in $procs) {
                Write-Host ("Parando processo Trae (PID {0})..." -f $p.Id) -ForegroundColor Yellow
                try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch { Write-Warning $_ }
            }
        } else {
            Write-Host "Trae não está em execução." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Falha ao verificar/encerrar processos do Trae: $($_.Exception.Message)"
    }
}

function Find-CookieFiles {
    param(
        [string[]]$Roots
    )
    $found = @()
    foreach ($root in $Roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Write-Host "Procurando cookies em: $root" -ForegroundColor Cyan
        try {
            # Procura arquivos com nome exato "Cookies" e "Cookies-journal" em todos os subdiretórios
            $found += Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq 'Cookies' -or $_.Name -eq 'Cookies-journal' }
        } catch {
            Write-Warning "Erro ao procurar em ${root}: $($_.Exception.Message)"
        }
    }
    $found | Sort-Object FullName -Unique
}

function Find-TargetDirectories {
    param(
        [string[]]$Roots,
        [string[]]$Names
    )
    $found = @()
    foreach ($root in $Roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Write-Host "Procurando diretórios alvo em: $root" -ForegroundColor Cyan
        try {
            $found += Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -ErrorAction SilentlyContinue |
                Where-Object { $Names -contains $_.Name }
        } catch {
            Write-Warning "Erro ao procurar diretórios em ${root}: $($_.Exception.Message)"
        }
    }
    $found | Sort-Object FullName -Unique
}

function Backup-Files {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$Destination
    )
    if (-not $Files -or $Files.Count -eq 0) { return }
    try {
        if (-not (Test-Path -LiteralPath $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        Write-Host "Fazendo backup de cookies em: $Destination" -ForegroundColor Yellow
        foreach ($f in $Files) {
            try {
                $safeName = ($f.FullName -replace '[:\\/]', '_')
                $dest = Join-Path $Destination $safeName
                Copy-Item -LiteralPath $f.FullName -Destination $dest -Force -ErrorAction Stop
            } catch {
                Write-Warning "Falha ao copiar $($f.FullName): $($_.Exception.Message)"
            }
        }
    } catch {
        Write-Warning "Falha no backup: $($_.Exception.Message)"
    }
}

function Backup-Directories {
    param(
        [System.IO.DirectoryInfo[]]$Dirs,
        [string]$Destination
    )
    if (-not $Dirs -or $Dirs.Count -eq 0) { return }
    try {
        if (-not (Test-Path -LiteralPath $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        Write-Host "Fazendo backup de diretórios em: $Destination" -ForegroundColor Yellow
        foreach ($d in $Dirs) {
            try {
                $safeName = ($d.FullName -replace '[:\\/]', '_')
                $dest = Join-Path $Destination $safeName
                Copy-Item -LiteralPath $d.FullName -Destination $dest -Recurse -Force -ErrorAction Stop
            } catch {
                Write-Warning "Falha ao copiar $($d.FullName): $($_.Exception.Message)"
            }
        }
    } catch {
        Write-Warning "Falha no backup de diretórios: $($_.Exception.Message)"
    }
}

function Remove-CookieFiles {
    param(
        [System.IO.FileInfo[]]$Files
    )
    if (-not $Files -or $Files.Count -eq 0) {
        Write-Host "Nenhum arquivo de cookie encontrado." -ForegroundColor Green
        return
    }

    Write-Host ("Encontrados {0} arquivos de cookies para remover." -f $Files.Count) -ForegroundColor Cyan

    foreach ($f in $Files) {
        try {
            # Remove atributo de somente leitura, se houver
            try {
                $item = Get-Item -LiteralPath $f.FullName -ErrorAction Stop
                if ($item.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                    $item.Attributes = ($item.Attributes -bxor [System.IO.FileAttributes]::ReadOnly)
                }
            } catch {}

            if ($PSCmdlet.ShouldProcess($f.FullName, 'Delete')) {
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                Write-Host "Apagado: $($f.FullName)" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Falha ao apagar $($f.FullName): $($_.Exception.Message)"
        }
    }
}

function Remove-Directories {
    param(
        [System.IO.DirectoryInfo[]]$Dirs
    )
    if (-not $Dirs -or $Dirs.Count -eq 0) {
        Write-Host "Nenhum diretório alvo encontrado." -ForegroundColor Green
        return
    }

    Write-Host ("Encontrados {0} diretórios para remover." -f $Dirs.Count) -ForegroundColor Cyan

    foreach ($d in $Dirs) {
        try {
            if ($PSCmdlet.ShouldProcess($d.FullName, 'Delete')) {
                Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
                Write-Host "Apagado diretório: $($d.FullName)" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Falha ao apagar $($d.FullName): $($_.Exception.Message)"
        }
    }
}

# 1) Encerrar Trae para evitar bloqueios
Stop-TraeProcesses

# 2) Definir pastas alvo
$appDataTrae = Join-Path $env:APPDATA 'Trae'
$localAppDataTrae = Join-Path $env:LOCALAPPDATA 'Trae'
$roots = @($appDataTrae, $localAppDataTrae)

# 3) Localizar arquivos de cookies
$cookieFiles = Find-CookieFiles -Roots $roots

# 4) Backup (opcional)
if ($Backup) {
    Backup-Files -Files $cookieFiles -Destination $BackupDir
}

# 5) Remover cookies
Remove-CookieFiles -Files $cookieFiles

# 6) Limpar storages e caches (se solicitado ou -All)
if ($IncludeStorage -or $IncludeCaches) {
    $storageNames = @('Local Storage','IndexedDB','Session Storage')
    $cacheNames   = @('Cache','Service Worker','GPUCache','Code Cache','blob_storage','DawnCache')

    $names = @()
    if ($IncludeStorage) { $names += $storageNames }
    if ($IncludeCaches)  { $names += $cacheNames }

    $targetDirs = Find-TargetDirectories -Roots $roots -Names $names

    if ($Backup) {
        Backup-Directories -Dirs $targetDirs -Destination $BackupDir
    }

    Remove-Directories -Dirs $targetDirs
}

Write-Host "Done. Restart Trae and sign in again if needed." -ForegroundColor Cyan