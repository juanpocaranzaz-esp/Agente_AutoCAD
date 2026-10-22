@echo off
setlocal enabledelayedexpansion
title Instalador Agente AutoCAD 2021 MCP

pushd "%~dp0"

echo =========================================================================
echo   Instalador Visual - Agente AutoCAD 2021 MCP (Casa / Oficina) v1.4.9
echo =========================================================================
echo Iniciando asistente visual de configuracion...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer_gui.ps1"

popd
