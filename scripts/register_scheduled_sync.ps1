# Registra la tarea programada de Windows para sincronizar cada 5 minutos
# Uso: powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_sync.ps1

$taskName = "AgenteAutoCAD_Sync_GitHub_5min"
$legacyTaskName = "AgenteAutoCAD_Sync_GitHub_15min"
$scriptPath = Join-Path $PSScriptRoot "sync_from_github.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Error "No se encontro el script de sincronizacion en $scriptPath"
    exit 1
}

# Desregistrar tarea anterior si existe
if (Get-ScheduledTask -TaskName $legacyTaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $legacyTaskName -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File ""$scriptPath"""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Sincroniza automaticamente Agente_AutoCAD y Biblioteca_LISP desde GitHub cada 5 minutos." -User $env:USERNAME -Force

Write-Host "Tarea programada '$taskName' registrada exitosamente para ejecutarse cada 5 minutos." -ForegroundColor Green
