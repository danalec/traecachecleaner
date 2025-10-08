# Limpiador de Caché y Cookies de Trae

Script de PowerShell para limpiar las cookies de la aplicación Trae y, opcionalmente, los storages/caches en:
- %APPDATA%\Trae
- %LOCALAPPDATA%\Trae

Ayuda a resolver problemas causados por cookies corruptas o datos de sitio inconsistentes (por ejemplo, problemas de inicio de sesión/sesión de Figma en el modo solo de Trae).

## Problema común que resuelve este script

Al iniciar sesión en Figma dentro de Trae (modo solo), aceptar el banner de cookies ("Allow all cookies") puede llevar a una sesión dañada y mostrar una página negra con el mensaje "Service is unavailable." Esto suele ocurrir debido a cookies corruptas o datos de sitio incompatibles almacenados por el navegador integrado de Trae (cookies, Local Storage, IndexedDB o cachés de particiones).

Ilustración:

![Aceptar cookies en Figma provoca "Service is unavailable"](assets/figma-login-issue.png)

### Cómo ayuda el script
- Elimina archivos de cookies que pueden mantener un estado de inicio de sesión inconsistente.
- Opcionalmente borra entradas de Local Storage e IndexedDB que pueden entrar en conflicto con nuevas sesiones.
- Opcionalmente limpia cachés y datos de partición utilizados por el navegador integrado.

### Pasos recomendados
1. Cierra Trae completamente.
2. Ejecuta una limpieza completa:
   ```powershell
   ./Clear-TraeCookies.ps1 -All
   ```
3. Reinicia Trae e intenta iniciar sesión en Figma nuevamente. Acepta las cookies cuando se te solicite.
4. Si el problema persiste, vuelve a ejecutar con `-Backup -All` para mantener una copia de seguridad y vuelve a intentarlo. También puedes compartir la copia para diagnóstico.

## Funcionalidades
- Detiene procesos de Trae para evitar archivos bloqueados
- Elimina archivos de cookies (Cookies y Cookies-journal) en todos los perfiles
- Limpieza opcional de Local Storage, IndexedDB, Session Storage y varias cachés (GPUCache, Code Cache, blob_storage, Service Worker, Cache, DawnCache)
- Copia de seguridad opcional de todos los archivos/directorios antes de borrar
- Modo de simulación (dry‑run) para previsualizar las acciones

## Requisitos
- Windows con PowerShell 5.1+ o PowerShell 7+

## Uso
Abre PowerShell en la carpeta del proyecto:

```powershell
Set-Location "c:\Users\danalec\Documents\src\traecachecleaner"
```

Ejecuta uno de los siguientes:

```powershell
# Limpiar solo cookies
./Clear-TraeCookies.ps1

# Copia de seguridad antes de borrar
./Clear-TraeCookies.ps1 -Backup

# Limpiar todo (cookies + storages + cachés)
./Clear-TraeCookies.ps1 -All

# Simulación: mostrar lo que se borraría
./Clear-TraeCookies.ps1 -WhatIf
```

Si la ejecución de scripts está bloqueada, usa temporalmente bypass:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; ./Clear-TraeCookies.ps1 -All
```

## Notas
- Después de la limpieza, reinicia Trae e inicia sesión nuevamente si es necesario.
- Usar `-All` borrará datos del sitio y cachés; las sesiones se limpiarán.
- Las copias de seguridad se guardan en `%TEMP%/TraeCookiesBackup_yyyyMMdd_HHmmss/`, salvo que indiques otra ruta.

## Qué se limpia
- Cookies: `Cookies`, `Cookies-journal`
- Storages (cuando está habilitado): `Local Storage`, `IndexedDB`, `Session Storage`
- Cachés (cuando están habilitadas): `GPUCache`, `Code Cache`, `blob_storage`, `Service Worker`, `Cache`, `DawnCache`

## Aviso
Este script elimina datos de la aplicación. Úsalo bajo tu propia responsabilidad. Considera usar `-Backup` primero para poder restaurar si es necesario.
