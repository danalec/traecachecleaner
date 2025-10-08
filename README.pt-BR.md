# Limpador de Cache e Cookies do Trae

Script PowerShell para limpar cookies do aplicativo Trae e, opcionalmente, storages/caches em:
- %APPDATA%\Trae
- %LOCALAPPDATA%\Trae

Ajuda a resolver problemas causados por cookies corrompidos ou dados de site inconsistentes (por exemplo, problemas de login/sessão do Figma no modo solo do Trae).

## Problema comum que este script resolve

Ao fazer login no Figma dentro do Trae (modo solo), aceitar o banner de cookies ("Allow all cookies") pode levar a uma sessão quebrada e exibir uma página preta com a mensagem "Service is unavailable." Isso geralmente acontece devido a cookies corrompidos ou dados de site inconsistentes armazenados pelo navegador embutido do Trae (cookies, Local Storage, IndexedDB ou caches de partições).

Ilustração:

![Aceitar cookies no Figma levando a "Service is unavailable"](assets/figma-login-issue.png)

Se a imagem acima não carregar no GitHub, salve a captura de tela em:
`assets/figma-login-issue.png` (relativo a este repositório)

### Como o script ajuda
- Remove arquivos de cookies que podem manter um estado de login inconsistente/quebrado.
- Opcionalmente exclui entradas de Local Storage e IndexedDB que podem conflitar com novas sessões.
- Opcionalmente limpa caches e dados de partição usados pelo navegador embutido.

### Passos recomendados
1. Feche o Trae completamente.
2. Execute uma limpeza completa:
   ```powershell
   ./Clear-TraeCookies.ps1 -All
   ```
3. Reinicie o Trae e tente fazer login no Figma novamente. Aceite os cookies quando solicitado.
4. Se o problema persistir, execute novamente com `-Backup -All` para manter um backup e tentar de novo. Você também pode compartilhar o backup para análise.

## Recursos
- Encerra processos do Trae para evitar arquivos bloqueados
- Remove arquivos de cookies (Cookies e Cookies-journal) em todos os perfis
- Limpeza opcional de Local Storage, IndexedDB, Session Storage e vários caches (GPUCache, Code Cache, blob_storage, Service Worker, Cache, DawnCache)
- Backup opcional de todos os arquivos/diretórios antes da remoção
- Modo de simulação (dry‑run) para visualizar as ações

## Requisitos
- Windows com PowerShell 5.1+ ou PowerShell 7+

## Uso
Abra o PowerShell na pasta do projeto:

```powershell
Set-Location "c:\Users\danalec\Documents\src\traecachecleaner"
```

Execute um dos seguintes:

```powershell
# Limpar apenas cookies
./Clear-TraeCookies.ps1

# Fazer backup dos cookies antes de apagar
./Clear-TraeCookies.ps1 -Backup

# Limpar tudo (cookies + storages + caches)
./Clear-TraeCookies.ps1 -All

# Simulação: mostrar o que seria apagado
./Clear-TraeCookies.ps1 -WhatIf
```

Se a execução de scripts estiver bloqueada, rode temporariamente com bypass:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; ./Clear-TraeCookies.ps1 -All
```

## Notas
- Após a limpeza, reinicie o Trae e faça login novamente, se necessário.
- Usar `-All` apagará dados de site e caches; sessões serão limpas.
- Backups são salvos em `%TEMP%/TraeCookiesBackup_yyyyMMdd_HHmmss/`, a menos que você forneça um caminho personalizado.

## O que é limpo
- Cookies: `Cookies`, `Cookies-journal`
- Storages (quando habilitado): `Local Storage`, `IndexedDB`, `Session Storage`
- Caches (quando habilitado): `GPUCache`, `Code Cache`, `blob_storage`, `Service Worker`, `Cache`, `DawnCache`

## Aviso
Este script apaga dados do aplicativo. Use por sua conta e risco. Considere usar `-Backup` primeiro para poder restaurar, se necessário.