@echo off
setlocal enabledelayedexpansion
echo =========================================================================
echo   Instalador Local - Agente AutoCAD 2021 (Casa / Oficina) v1.4.9
echo =========================================================================

pushd "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [1/4] Creando entorno virtual Python (.venv)...
    python -m venv .venv
) else (
    echo [1/4] Entorno virtual .venv ya existe.
)

echo [2/4] Instalando librerias del servidor MCP...
".venv\Scripts\pip.exe" install --upgrade pip
".venv\Scripts\pip.exe" install -r requirements.txt

if not exist "mcp-autocad\temp" mkdir "mcp-autocad\temp"
if not exist "mcp-autocad\logs" mkdir "mcp-autocad\logs"
if not exist "lisp-library" mkdir "lisp-library"

echo [3/4] Creando enlaces globales de Skills para Google Antigravity y OpenAI Codex...
set "GEMINI_SKILLS=%USERPROFILE%\.gemini\config\skills"
set "CODEX_SKILLS=%USERPROFILE%\.codex\skills"
if not exist "%GEMINI_SKILLS%" mkdir "%GEMINI_SKILLS%"
if not exist "%CODEX_SKILLS%" mkdir "%CODEX_SKILLS%"

for /D %%S in (".agents\skills\*") do (
    set "SKILL_NAME=%%~nxS"
    if exist "%%S\SKILL.md" (
        if exist "%GEMINI_SKILLS%\!SKILL_NAME!" rmdir "%GEMINI_SKILLS%\!SKILL_NAME!" 2>nul
        mklink /J "%GEMINI_SKILLS%\!SKILL_NAME!" "%%~fS" 2>nul || xcopy /E /I /Y "%%~fS" "%GEMINI_SKILLS%\!SKILL_NAME!" >nul
        echo     + Vinculada skill global !SKILL_NAME! en Antigravity
        if exist "%CODEX_SKILLS%\!SKILL_NAME!" rmdir "%CODEX_SKILLS%\!SKILL_NAME!" 2>nul
        mklink /J "%CODEX_SKILLS%\!SKILL_NAME!" "%%~fS" 2>nul || xcopy /E /I /Y "%%~fS" "%CODEX_SKILLS%\!SKILL_NAME!" >nul
        echo     + Vinculada skill global !SKILL_NAME! en OpenAI Codex
    )
)

echo [4/4] Verificando accoreconsole de AutoCAD...
set "FOUND_ACCORE="
for %%P in (
    "C:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe"
    "C:\Program Files\Autodesk\AutoCAD 2022\accoreconsole.exe"
    "C:\Program Files\Autodesk\AutoCAD 2023\accoreconsole.exe"
    "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe"
    "C:\Program Files\Autodesk\AutoCAD 2025\accoreconsole.exe"
    "D:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe"
    "D:\Program Files\Autodesk\AutoCAD 2022\accoreconsole.exe"
    "D:\Program Files\Autodesk\AutoCAD 2023\accoreconsole.exe"
    "D:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe"
    "D:\Program Files\Autodesk\AutoCAD 2025\accoreconsole.exe"
) do (
    if not defined FOUND_ACCORE (
        if exist %%P (
            set "FOUND_ACCORE=%%~fP"
        )
    )
)
if defined FOUND_ACCORE (
    echo     OK: accoreconsole.exe detectado en: !FOUND_ACCORE!
) else (
    echo     AVISO: No se encontro accoreconsole en C:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe.
    echo     Verifica la ruta en caso de tener una instalacion personalizada.
)

echo.
echo =========================================================================
echo   Instalacion completada en: %CD%
echo [5/5] Registrando servidor MCP en Antigravity, OpenAI Codex y Claude Desktop...
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
".venv\Scripts\python.exe" -c "import json, os, pathlib, re; root = pathlib.Path(os.environ.get('SCRIPT_DIR', '.')).resolve(); acad_p = os.environ.get('FOUND_ACCORE', 'C:/Program Files/Autodesk/AutoCAD 2021/accoreconsole.exe').replace('\\', '/'); extra_lisp = os.environ.get('ACAD_EXTRA_LISP_DIRS', ''); srv_env = {'ACAD_CONSOLE_PATH': acad_p, 'AGENTE_ROOT': str(root)}; (srv_env.__setitem__('ACAD_EXTRA_LISP_DIRS', extra_lisp)) if extra_lisp else None; srv_entry = {'command': str(root / '.venv' / 'Scripts' / 'python.exe'), 'args': [str(root / 'mcp-autocad' / 'server.py')], 'env': srv_env}; cfg_p = pathlib.Path(os.path.expanduser('~/.gemini/config/mcp_config.json')); cfg_p.parent.mkdir(parents=True, exist_ok=True); cfg = json.loads(cfg_p.read_text(encoding='utf-8')) if cfg_p.exists() else {}; srvs = cfg.setdefault('mcpServers', {}); srvs['autocad-2021'] = srv_entry; cfg_p.write_text(json.dumps(cfg, indent=2), encoding='utf-8'); print('    + Servidor MCP registrado en Antigravity:', cfg_p); codex_p = pathlib.Path(os.path.expanduser('~/.codex/config.toml')); codex_p.parent.mkdir(parents=True, exist_ok=True); c_txt = codex_p.read_text(encoding='utf-8') if codex_p.exists() else ''; ev = str(root / '.venv' / 'Scripts' / 'python.exe').replace('\\', '\\\\'); es = str(root / 'mcp-autocad' / 'server.py').replace('\\', '\\\\'); ea = acad_p.replace('/', '\\\\'); er = str(root).replace('\\', '\\\\'); extra_toml = f', ACAD_EXTRA_LISP_DIRS = \"{extra_lisp.replace(chr(92), chr(92)+chr(92))}\"' if extra_lisp else ''; toml_snip = f'\n[mcp_servers.autocad_2021]\ncommand = \"{ev}\"\nargs = [\"{es}\"]\nenv = {{ ACAD_CONSOLE_PATH = \"{ea}\", AGENTE_ROOT = \"{er}\"{extra_toml} }}\n'; c_txt = re.sub(r'(?ms)\[mcp_servers\.autocad_2021\].*?(?=(\r?\n\[|$))', toml_snip.strip(), c_txt) if re.search(r'(?ms)\[mcp_servers\.autocad_2021\].*?(?=(\r?\n\[|$))', c_txt) else (c_txt + toml_snip); codex_p.write_text(c_txt, encoding='utf-8'); print('    + Servidor MCP registrado en OpenAI Codex:', codex_p); claude_dir = pathlib.Path(os.path.expandvars(r'%%APPDATA%%\Claude')); (claude_p := claude_dir / 'claude_desktop_config.json', claude_p.parent.mkdir(parents=True, exist_ok=True), (c_cfg := json.loads(claude_p.read_text(encoding='utf-8')) if claude_p.exists() else {}), c_cfg.setdefault('mcpServers', {}).__setitem__('autocad-2021', srv_entry), claude_p.write_text(json.dumps(c_cfg, indent=2), encoding='utf-8'), print('    + Servidor MCP registrado en Claude Desktop:', claude_p)) if claude_dir.parent.exists() else None"
echo =========================================================================
popd
pause
