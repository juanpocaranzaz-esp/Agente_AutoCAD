# Registra la tarea programada de Windows para sincronizar cada 5 minutos de forma 100% silenciosa
# Uso: powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_sync.ps1

$taskName = "AgenteAutoCAD_Sync_GitHub_5min"
$legacyTaskName = "AgenteAutoCAD_Sync_GitHub_15min"
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$vbsPath = Join-Path $scriptDir "run_sync_hidden.vbs"

if (-not (Test-Path $vbsPath)) {
    Write-Error "No se encontro el lanzador silencioso en $vbsPath"
    exit 1
}

# Desregistrar tarea anterior si existe
if (Get-ScheduledTask -TaskName $legacyTaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $legacyTaskName -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "//B //nologo `"$vbsPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Sincroniza silenciosamente Agente_AutoCAD y Biblioteca_LISP desde GitHub cada 5 minutos sin ventana ni robo de foco." -User $env:USERNAME -Force

Write-Host "Tarea programada '$taskName' registrada exitosamente con ejecucion 100% silenciosa (sin ventana ni robo de foco)." -ForegroundColor Green
