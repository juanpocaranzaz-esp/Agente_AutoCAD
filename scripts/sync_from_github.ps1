# Sincronizador automatico desde GitHub para Agente AutoCAD y Biblioteca_LISP
# Ejecutado periodicamente cada 5 minutos via Programador de Tareas de Windows (Task Scheduler)

$ErrorActionPreference = "Continue"
$env:GIT_TERMINAL_PROMPT = "0"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path $logDir "github_sync.log"

function Log-Message ($msg) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] $msg"
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

function Sync-Repo ($repoPath, $repoName, $isNetwork = $false) {
    Log-Message "Iniciando verificacion para $repoName ($repoPath)..."
    if (-not (Test-Path $repoPath)) {
        Log-Message "ADVERTENCIA: La ruta $repoPath no esta accesible."
        return
    }

    try {
        $gitArgsPrefix = @()
        if ($isNetwork) {
            $gitArgsPrefix += "-c", "safe.directory=*"
        }

        # 1. Verificar estado local para evitar sobreescribir cambios no confirmados en archivos rastreados
        $diffCmd = @() + $gitArgsPrefix + @("-C", $repoPath, "diff", "--stat")
        $trackedDiff = & git $diffCmd 2>&1
        if ($trackedDiff -and $trackedDiff.Trim().Length -gt 0) {
            Log-Message "AVISO: $repoName tiene cambios locales sin confirmar. Saltando pull para evitar colisiones."
            return
        }

        # 2. Fetch de origin
        $fetchCmd = @() + $gitArgsPrefix + @("-C", $repoPath, "fetch", "origin", "main")
        $fetchRes = & git $fetchCmd 2>&1
        if ($LASTEXITCODE -ne 0) {
            Log-Message "ERROR en git fetch ($repoName) - $fetchRes"
            return
        }

        # 3. Comparar HEAD con origin/main
        $localRev = (& git @($gitArgsPrefix + @("-C", $repoPath, "rev-parse", "HEAD"))).Trim()
        $remoteRev = (& git @($gitArgsPrefix + @("-C", $repoPath, "rev-parse", "origin/main"))).Trim()

        if ($localRev -eq $remoteRev) {
            Log-Message "$repoName ya se encuentra al dia con origin/main ($localRev)."
        } else {
            Log-Message "Actualizaciones detectadas en origin/main ($remoteRev). Aplicando pull --ff-only..."
            $pullCmd = @() + $gitArgsPrefix + @("-C", $repoPath, "pull", "--ff-only", "origin", "main")
            $pullRes = & git $pullCmd 2>&1
            if ($LASTEXITCODE -eq 0) {
                Log-Message "EXITO: $repoName actualizado correctamente a $remoteRev."
            } else {
                Log-Message "AVISO: Fast-forward no fue posible ($pullRes). Intentando git pull --rebase..."
                $rebaseCmd = @() + $gitArgsPrefix + @("-C", $repoPath, "pull", "--rebase", "--autostash", "origin", "main")
                $rebaseRes = & git $rebaseCmd 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Log-Message "EXITO: $repoName actualizado con rebase a $remoteRev."
                } else {
                    Log-Message "ERROR al sincronizar $repoName - $rebaseRes"
                }
            }
        }
    } catch {
        $errText = $_.ToString()
        Log-Message "EXCEPCION al sincronizar $repoName - $errText"
    }
}

Log-Message "=== INICIO CICLO SINCRONIZACION GITHUB ==="
Sync-Repo $projectRoot "Agente_AutoCAD" $false

# Sincronizar directorio de LISP en red si esta definido y existe
if ($env:ACAD_EXTRA_LISP_DIRS -and (Test-Path $env:ACAD_EXTRA_LISP_DIRS)) {
    Sync-Repo $env:ACAD_EXTRA_LISP_DIRS "Biblioteca_LISP" $true
} elseif (Test-Path "\\bashemdc\ESTUDIO\PROGRAMAS\Lisps-AutoCAD\Biblioteca_LISP") {
    Sync-Repo "\\bashemdc\ESTUDIO\PROGRAMAS\Lisps-AutoCAD\Biblioteca_LISP" "Biblioteca_LISP" $true
}

# Mantener tamano de log controlado (rotar si supera 2MB)
if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt 2MB)) {
    $archive = Join-Path $logDir "github_sync_old.log"
    Move-Item -Path $logFile -Destination $archive -Force
}
Log-Message "=== FIN CICLO SINCRONIZACION ==="
