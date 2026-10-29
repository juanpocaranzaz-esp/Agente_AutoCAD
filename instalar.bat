@echo off
setlocal enabledelayedexpansion
title Instalador Agente AutoCAD 2021 MCP

pushd "%~dp0"

echo =========================================================================
echo   Instalador Visual - Agente AutoCAD 2021 MCP v2.0.0
echo =========================================================================
echo Iniciando asistente visual de configuracion...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer_gui.ps1"

popd
