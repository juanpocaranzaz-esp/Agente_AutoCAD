# installer_gui.ps1
# Asistente Visual de Instalacion y Configuracion del Agente AutoCAD 2021 MCP (v1.4.9)
# Compatible con Windows 10 y Windows 11 (PowerShell 5.1+)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Instalador del Agente de AutoCAD 2021 MCP (v1.4.9)"
$form.Size = New-Object System.Drawing.Size(680, 720)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(248, 250, 252)

# --- Encabezado ---
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(680, 80)
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 95)
$form.Controls.Add($headerPanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Agente Autónomo AutoCAD 2021 MCP"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Location = New-Object System.Drawing.Point(24, 14)
$titleLabel.Size = New-Object System.Drawing.Size(630, 30)
$headerPanel.Controls.Add($titleLabel)

$subTitleLabel = New-Object System.Windows.Forms.Label
$subTitleLabel.Text = "Asistente de configuración de estaciones de trabajo (Casa / Estudio)"
$subTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$subTitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(226, 232, 240)
$subTitleLabel.Location = New-Object System.Drawing.Point(26, 44)
$subTitleLabel.Size = New-Object System.Drawing.Size(630, 24)
$headerPanel.Controls.Add($subTitleLabel)

# --- Grupo 1: Ubicación del Agente ---
$grpInstall = New-Object System.Windows.Forms.GroupBox
$grpInstall.Text = "1. Ubicación de Instalación del Agente y Servidor MCP"
$grpInstall.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$grpInstall.Location = New-Object System.Drawing.Point(24, 96)
$grpInstall.Size = New-Object System.Drawing.Size(616, 150)
$form.Controls.Add($grpInstall)

$rbOpt1 = New-Object System.Windows.Forms.RadioButton
$rbOpt1.Text = "C:\AgenteCAD  (Recomendada - Sin espacios y ruta corta)"
$rbOpt1.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$rbOpt1.Location = New-Object System.Drawing.Point(20, 26)
$rbOpt1.Size = New-Object System.Drawing.Size(560, 24)
$rbOpt1.Checked = $true
$grpInstall.Controls.Add($rbOpt1)

$userProfilePath = [System.IO.Path]::Combine($env:USERPROFILE, "AgenteCAD")
$rbOpt2 = New-Object System.Windows.Forms.RadioButton
$rbOpt2.Text = "$userProfilePath  (Carpeta del usuario actual)"
$rbOpt2.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$rbOpt2.Location = New-Object System.Drawing.Point(20, 54)
$rbOpt2.Size = New-Object System.Drawing.Size(560, 24)
$grpInstall.Controls.Add($rbOpt2)

$rbOpt3 = New-Object System.Windows.Forms.RadioButton
$rbOpt3.Text = "Ruta personalizada:"
$rbOpt3.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$rbOpt3.Location = New-Object System.Drawing.Point(20, 82)
$rbOpt3.Size = New-Object System.Drawing.Size(150, 24)
$grpInstall.Controls.Add($rbOpt3)

$txtCustomPath = New-Object System.Windows.Forms.TextBox
$txtCustomPath.Location = New-Object System.Drawing.Point(170, 82)
$txtCustomPath.Size = New-Object System.Drawing.Size(320, 24)
$txtCustomPath.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$txtCustomPath.Enabled = $false
$grpInstall.Controls.Add($txtCustomPath)

$btnBrowseInstall = New-Object System.Windows.Forms.Button
$btnBrowseInstall.Text = "Examinar..."
$btnBrowseInstall.Location = New-Object System.Drawing.Point(500, 80)
$btnBrowseInstall.Size = New-Object System.Drawing.Size(95, 27)
$btnBrowseInstall.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$btnBrowseInstall.Enabled = $false
$grpInstall.Controls.Add($btnBrowseInstall)

$lblPathWarning = New-Object System.Windows.Forms.Label
$lblPathWarning.Text = ""
$lblPathWarning.ForeColor = [System.Drawing.Color]::Firebrick
$lblPathWarning.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblPathWarning.Location = New-Object System.Drawing.Point(20, 114)
$lblPathWarning.Size = New-Object System.Drawing.Size(575, 24)
$grpInstall.Controls.Add($lblPathWarning)

# Logica de seleccion de ruta
$script:GetSelectedInstallPath = {
    if ($rbOpt1.Checked) { return "C:\AgenteCAD" }
    elseif ($rbOpt2.Checked) { return $userProfilePath }
    else { return $txtCustomPath.Text.Trim() }
}

$script:CheckPathSafety = {
    $p = & $script:GetSelectedInstallPath
    if ([string]::IsNullOrWhiteSpace($p)) {
        $lblPathWarning.Text = "Aviso: Debes especificar una ruta válida."
        $lblPathWarning.ForeColor = [System.Drawing.Color]::Firebrick
        return $false
    }
    if ($p.ToLower().Contains("cad proyect")) {
        $lblPathWarning.Text = "Aviso: La ruta contiene 'cad proyect' (se activará modo staging de desarrollo)."
        $lblPathWarning.ForeColor = [System.Drawing.Color]::DarkOrange
        return $true
    }
    if ($p.Contains(" ")) {
        $lblPathWarning.Text = "Aviso: La ruta contiene espacios. Se recomienda 'C:\AgenteCAD' para AutoCAD."
        $lblPathWarning.ForeColor = [System.Drawing.Color]::DarkOrange
        return $true
    }
    $lblPathWarning.Text = "Ruta limpia y válida."
    $lblPathWarning.ForeColor = [System.Drawing.Color]::DarkGreen
    return $true
}

$rbOpt1.Add_CheckedChanged({
    $txtCustomPath.Enabled = $false
    $btnBrowseInstall.Enabled = $false
    & $script:CheckPathSafety
})

$rbOpt2.Add_CheckedChanged({
    $txtCustomPath.Enabled = $false
    $btnBrowseInstall.Enabled = $false
    & $script:CheckPathSafety
})

$rbOpt3.Add_CheckedChanged({
    $txtCustomPath.Enabled = $rbOpt3.Checked
    $btnBrowseInstall.Enabled = $rbOpt3.Checked
    & $script:CheckPathSafety
})

$txtCustomPath.Add_TextChanged({ & $script:CheckPathSafety })

$btnBrowseInstall.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Selecciona la carpeta donde deseas instalar el Agente de AutoCAD"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtCustomPath.Text = $dlg.SelectedPath
    }
})

# --- Grupo 2: Biblioteca de LISPs de Red / Estudio ---
$grpLisp = New-Object System.Windows.Forms.GroupBox
$grpLisp.Text = "2. Biblioteca Externa de AutoLISP (Red / Estudio)"
$grpLisp.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$grpLisp.Location = New-Object System.Drawing.Point(24, 256)
$grpLisp.Size = New-Object System.Drawing.Size(616, 100)
$form.Controls.Add($grpLisp)

$chkEnableExternalLisp = New-Object System.Windows.Forms.CheckBox
$chkEnableExternalLisp.Text = "Vincular biblioteca de LISPs del estudio (ACAD_EXTRA_LISP_DIRS)"
$chkEnableExternalLisp.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$chkEnableExternalLisp.Location = New-Object System.Drawing.Point(20, 26)
$chkEnableExternalLisp.Size = New-Object System.Drawing.Size(560, 24)
$chkEnableExternalLisp.Checked = $true
$grpLisp.Controls.Add($chkEnableExternalLisp)

$txtLispNetworkPath = New-Object System.Windows.Forms.TextBox
$txtLispNetworkPath.Text = "\\bashemdc\ESTUDIO\PROGRAMAS\"
$txtLispNetworkPath.Location = New-Object System.Drawing.Point(20, 58)
$txtLispNetworkPath.Size = New-Object System.Drawing.Size(470, 24)
$txtLispNetworkPath.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpLisp.Controls.Add($txtLispNetworkPath)

$btnBrowseLisp = New-Object System.Windows.Forms.Button
$btnBrowseLisp.Text = "Examinar..."
$btnBrowseLisp.Location = New-Object System.Drawing.Point(500, 56)
$btnBrowseLisp.Size = New-Object System.Drawing.Size(95, 27)
$btnBrowseLisp.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpLisp.Controls.Add($btnBrowseLisp)

$chkEnableExternalLisp.Add_CheckedChanged({
    $txtLispNetworkPath.Enabled = $chkEnableExternalLisp.Checked
    $btnBrowseLisp.Enabled = $chkEnableExternalLisp.Checked
})

$btnBrowseLisp.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Selecciona la carpeta de rutinas AutoLISP externas"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtLispNetworkPath.Text = $dlg.SelectedPath
    }
})

# --- Grupo 3: Consola de AutoCAD (accoreconsole.exe) ---
$grpAcad = New-Object System.Windows.Forms.GroupBox
$grpAcad.Text = "3. Motor de AutoCAD (accoreconsole.exe)"
$grpAcad.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$grpAcad.Location = New-Object System.Drawing.Point(24, 366)
$grpAcad.Size = New-Object System.Drawing.Size(616, 90)
$form.Controls.Add($grpAcad)

$txtAcadPath = New-Object System.Windows.Forms.TextBox
$txtAcadPath.Location = New-Object System.Drawing.Point(20, 32)
$txtAcadPath.Size = New-Object System.Drawing.Size(470, 24)
$txtAcadPath.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpAcad.Controls.Add($txtAcadPath)

$btnBrowseAcad = New-Object System.Windows.Forms.Button
$btnBrowseAcad.Text = "Examinar..."
$btnBrowseAcad.Location = New-Object System.Drawing.Point(500, 30)
$btnBrowseAcad.Size = New-Object System.Drawing.Size(95, 27)
$btnBrowseAcad.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpAcad.Controls.Add($btnBrowseAcad)

$lblAcadStatus = New-Object System.Windows.Forms.Label
$lblAcadStatus.Text = ""
$lblAcadStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblAcadStatus.Location = New-Object System.Drawing.Point(20, 60)
$lblAcadStatus.Size = New-Object System.Drawing.Size(575, 22)
$grpAcad.Controls.Add($lblAcadStatus)

# Autodeteccion de accoreconsole
$candidateAcadPaths = @(
    "C:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe",
    "C:\Program Files\Autodesk\AutoCAD 2022\accoreconsole.exe",
    "C:\Program Files\Autodesk\AutoCAD 2023\accoreconsole.exe",
    "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe",
    "C:\Program Files\Autodesk\AutoCAD 2025\accoreconsole.exe",
    "C:\Program Files\Autodesk\AutoCAD 2026\accoreconsole.exe",
    "D:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe",
    "D:\Program Files\Autodesk\AutoCAD 2022\accoreconsole.exe",
    "D:\Program Files\Autodesk\AutoCAD 2023\accoreconsole.exe",
    "D:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe"
)
$foundAcad = $null
foreach ($c in $candidateAcadPaths) {
    if (Test-Path $c) {
        $foundAcad = $c
        break
    }
}
if ($foundAcad) {
    $txtAcadPath.Text = $foundAcad
    $lblAcadStatus.Text = "Detectado automáticamente en disco."
    $lblAcadStatus.ForeColor = [System.Drawing.Color]::DarkGreen
} else {
    $txtAcadPath.Text = "C:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe"
    $lblAcadStatus.Text = "Ruta predeterminada (verifica si tu instalación es personalizada)."
    $lblAcadStatus.ForeColor = [System.Drawing.Color]::DarkOrange
}

$btnBrowseAcad.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "AutoCAD Core Console (accoreconsole.exe)|accoreconsole.exe|Todos los archivos (*.*)|*.*"
    $dlg.Title = "Selecciona accoreconsole.exe de tu versión de AutoCAD"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtAcadPath.Text = $dlg.FileName
        $lblAcadStatus.Text = "Ruta seleccionada manualmente."
        $lblAcadStatus.ForeColor = [System.Drawing.Color]::DarkGreen
    }
})

# --- Grupo 4: Configuracion de IDEs de IA ---
$grpIdes = New-Object System.Windows.Forms.GroupBox
$grpIdes.Text = "4. Registrar Servidor MCP en Entornos de IA (IDEs)"
$grpIdes.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$grpIdes.Location = New-Object System.Drawing.Point(24, 466)
$grpIdes.Size = New-Object System.Drawing.Size(616, 110)
$form.Controls.Add($grpIdes)

$chkAntigravity = New-Object System.Windows.Forms.CheckBox
$chkAntigravity.Text = "Google Antigravity (~/.gemini/config/mcp_config.json y Skills globales)"
$chkAntigravity.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$chkAntigravity.Location = New-Object System.Drawing.Point(20, 24)
$chkAntigravity.Size = New-Object System.Drawing.Size(560, 24)
$chkAntigravity.Checked = $true
$grpIdes.Controls.Add($chkAntigravity)

$chkCodex = New-Object System.Windows.Forms.CheckBox
$chkCodex.Text = "OpenAI Codex (~/.codex/config.toml y Skills globales)"
$chkCodex.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$chkCodex.Location = New-Object System.Drawing.Point(20, 50)
$chkCodex.Size = New-Object System.Drawing.Size(560, 24)
$chkCodex.Checked = $true
$grpIdes.Controls.Add($chkCodex)

$chkClaude = New-Object System.Windows.Forms.CheckBox
$chkClaude.Text = "Claude Desktop (%APPDATA%\Claude\claude_desktop_config.json)"
$chkClaude.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$chkClaude.Location = New-Object System.Drawing.Point(20, 76)
$chkClaude.Size = New-Object System.Drawing.Size(560, 24)
$chkClaude.Checked = $true
$grpIdes.Controls.Add($chkClaude)

# --- Barra Inferior: Estado y Botones ---
$lblStatusBottom = New-Object System.Windows.Forms.Label
$lblStatusBottom.Text = "Listo para iniciar la instalación."
$lblStatusBottom.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Italic)
$lblStatusBottom.Location = New-Object System.Drawing.Point(24, 588)
$lblStatusBottom.Size = New-Object System.Drawing.Size(616, 24)
$form.Controls.Add($lblStatusBottom)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(24, 614)
$progressBar.Size = New-Object System.Drawing.Size(616, 18)
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancelar"
$btnCancel.Location = New-Object System.Drawing.Point(400, 642)
$btnCancel.Size = New-Object System.Drawing.Size(110, 32)
$btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$form.Controls.Add($btnCancel)
$btnCancel.Add_Click({ $form.Close() })

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Instalar y Configurar"
$btnInstall.Location = New-Object System.Drawing.Point(520, 642)
$btnInstall.Size = New-Object System.Drawing.Size(120, 32)
$btnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnInstall.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 95)
$btnInstall.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnInstall)

# --- Proceso de Instalacion ---
$btnInstall.Add_Click({
    $targetDir = & $script:GetSelectedInstallPath
    if ([string]::IsNullOrWhiteSpace($targetDir)) {
        [System.Windows.Forms.MessageBox]::Show("Por favor especifica una ruta de instalación válida.", "Error de Ruta", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $acadExe = $txtAcadPath.Text.Trim()
    $lispNetwork = if ($chkEnableExternalLisp.Checked) { $txtLispNetworkPath.Text.Trim() } else { "" }

    # Desactivar controles durante la instalacion
    $btnInstall.Enabled = $false
    $btnCancel.Enabled = $false
    $progressBar.Visible = $true
    $progressBar.Value = 10

    $lblStatusBottom.Text = "[1/5] Extrayendo archivos del paquete de especificación..."
    $form.Refresh()

    try {
        # 1. Localizar archivo JSON maestro de especificacion o directorio fuente
        $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
        if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

        $sourceJson = $null
        $candJsons = Get-ChildItem -Path $scriptDir -Filter "especificacion_del_agente_y_mcp_autocad_2021-V*.json" | Sort-Object Name -Descending
        if ($candJsons.Count -gt 0) {
            $sourceJson = $candJsons[0].FullName
        }

        # 2. Desempaquetar o copiar archivos a la carpeta destino
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

        if ($sourceJson) {
            $rawJson = Get-Content -Path $sourceJson -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($d in $rawJson.directory_tree) {
                $dPath = Join-Path $targetDir $d
                New-Item -ItemType Directory -Path $dPath -Force | Out-Null
            }
            foreach ($f in $rawJson.files) {
                $rel = $f.path
                $cnt = $f.content
                $outPath = Join-Path $targetDir $rel
                $outDir = Split-Path $outPath -Parent
                if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
                [System.IO.File]::WriteAllText($outPath, $cnt, [System.Text.UTF8Encoding]::new($false))
            }
        } elseif (Test-Path (Join-Path $scriptDir "mcp-autocad\server.py")) {
            # Modo repositorio crudo / directorio fuente
            $resolvedSrc = (Resolve-Path $scriptDir).Path
            $resolvedDst = (Resolve-Path $targetDir -ErrorAction SilentlyContinue)
            $dstPath = if ($resolvedDst) { $resolvedDst.Path } else { $targetDir }
            if ($resolvedSrc -ne $dstPath) {
                foreach ($item in @(".agents", "lisp-library", "mcp-autocad", "requirements.txt", "setup_local.bat", "AGENTS.md", "MEMORY.md", ".gitignore")) {
                    $itemSrc = Join-Path $scriptDir $item
                    if (Test-Path $itemSrc) {
                        Copy-Item -Path $itemSrc -Destination (Join-Path $targetDir $item) -Recurse -Force
                    }
                }
            }
        } else {
            throw "No se encontró el archivo de especificación JSON ni los archivos del servidor en $scriptDir."
        }

        # Asegurar copia de instaladores auxiliares en destino
        foreach ($aux in @("installer_gui.ps1", "instalar.bat", "unpack_spec.py", "pack_spec.py")) {
            $auxSrc = Join-Path $scriptDir $aux
            if (Test-Path $auxSrc) {
                $auxDst = Join-Path $targetDir $aux
                if ((Resolve-Path $auxSrc -ErrorAction SilentlyContinue).Path -ne (Resolve-Path $auxDst -ErrorAction SilentlyContinue).Path) {
                    Copy-Item -Path $auxSrc -Destination $auxDst -Force
                }
            }
        }

        $progressBar.Value = 35
        $lblStatusBottom.Text = "[2/5] Creando entorno virtual de Python (.venv)..."
        $form.Refresh()

        $venvPy = Join-Path $targetDir ".venv\Scripts\python.exe"
        if (-not (Test-Path $venvPy)) {
            $p0 = Start-Process -FilePath "python" -ArgumentList "-m venv `"$targetDir\.venv`"" -Wait -NoNewWindow -PassThru
            if ($p0.ExitCode -ne 0 -or -not (Test-Path $venvPy)) {
                Start-Process -FilePath "py" -ArgumentList "-m venv `"$targetDir\.venv`"" -Wait -NoNewWindow -PassThru
            }
        }
        if (-not (Test-Path $venvPy)) {
            throw "No se pudo crear el entorno virtual. Verifica que Python esté instalado y en el PATH del sistema."
        }

        $progressBar.Value = 60
        $lblStatusBottom.Text = "[3/5] Instalando librerías del servidor MCP (mcp, pywin32, openpyxl, pypdfium2, Pillow)..."
        $form.Refresh()

        $pipExe = Join-Path $targetDir ".venv\Scripts\pip.exe"
        $reqFile = Join-Path $targetDir "requirements.txt"
        Start-Process -FilePath $pipExe -ArgumentList "install --upgrade pip" -Wait -NoNewWindow
        $p2 = Start-Process -FilePath $pipExe -ArgumentList "install -r `"$reqFile`"" -Wait -NoNewWindow -PassThru
        if ($p2.ExitCode -ne 0) { throw "Error al instalar librerías de requirements.txt." }

        $progressBar.Value = 75
        $lblStatusBottom.Text = "[4/5] Creando enlaces globales de Skills para Antigravity y Codex..."
        $form.Refresh()

        $skillsSrc = Join-Path $targetDir ".agents\skills"
        $geminiSkills = Join-Path $env:USERPROFILE ".gemini\config\skills"
        $codexSkills = Join-Path $env:USERPROFILE ".codex\skills"

        if ($chkAntigravity.Checked) { New-Item -ItemType Directory -Path $geminiSkills -Force | Out-Null }
        if ($chkCodex.Checked) { New-Item -ItemType Directory -Path $codexSkills -Force | Out-Null }

        if (Test-Path $skillsSrc) {
            Get-ChildItem -Path $skillsSrc -Directory | ForEach-Object {
                $skName = $_.Name
                $skTarget = $_.FullName
                if ($chkAntigravity.Checked) {
                    $gLink = Join-Path $geminiSkills $skName
                    if (Test-Path $gLink) {
                        cmd /c "rmdir `"$gLink`"" 2>$null
                    }
                    cmd /c "mklink /J `"$gLink`" `"$skTarget`"" 2>$null
                    if (-not (Test-Path $gLink)) {
                        Copy-Item -Path $skTarget -Destination $gLink -Recurse -Force
                    }
                }
                if ($chkCodex.Checked) {
                    $cLink = Join-Path $codexSkills $skName
                    if (Test-Path $cLink) {
                        cmd /c "rmdir `"$cLink`"" 2>$null
                    }
                    cmd /c "mklink /J `"$cLink`" `"$skTarget`"" 2>$null
                    if (-not (Test-Path $cLink)) {
                        Copy-Item -Path $skTarget -Destination $cLink -Recurse -Force
                    }
                }
            }
        }

        $progressBar.Value = 90
        $lblStatusBottom.Text = "[5/5] Registrando servidor MCP en los entornos seleccionados..."
        $form.Refresh()

        # Construir entrada MCP
        $serverPy = Join-Path $targetDir "mcp-autocad\server.py"
        $srvEntry = @{
            "command" = $venvPy
            "args" = @($serverPy)
            "env" = @{
                "ACAD_CONSOLE_PATH" = $acadExe
                "AGENTE_ROOT" = $targetDir
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($lispNetwork)) {
            $srvEntry.env["ACAD_EXTRA_LISP_DIRS"] = $lispNetwork
        }

        # 1. Antigravity
        if ($chkAntigravity.Checked) {
            $mcpJsonPath = Join-Path $env:USERPROFILE ".gemini\config\mcp_config.json"
            $mcpDir = Split-Path $mcpJsonPath -Parent
            if (-not (Test-Path $mcpDir)) { New-Item -ItemType Directory -Path $mcpDir -Force | Out-Null }
            $cfg = $null
            if (Test-Path $mcpJsonPath) {
                try {
                    $rawContent = Get-Content $mcpJsonPath -Raw
                    if (-not [string]::IsNullOrWhiteSpace($rawContent)) {
                        $cfg = $rawContent | ConvertFrom-Json
                    }
                } catch {}
            }
            if (-not $cfg) {
                $cfg = [PSCustomObject]@{ "mcpServers" = [PSCustomObject]@{} }
            }
            if (-not $cfg.psobject.properties['mcpServers']) {
                $cfg | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{}) -Force
            }
            if ($cfg.mcpServers.psobject.properties['autocad-2021']) {
                $cfg.mcpServers.'autocad-2021' = $srvEntry
            } else {
                $cfg.mcpServers | Add-Member -MemberType NoteProperty -Name 'autocad-2021' -Value $srvEntry -Force
            }
            $cfgJson = $cfg | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($mcpJsonPath, $cfgJson, [System.Text.UTF8Encoding]::new($false))
        }

        # 2. Codex
        if ($chkCodex.Checked) {
            $codexTomlPath = Join-Path $env:USERPROFILE ".codex\config.toml"
            $codexDir = Split-Path $codexTomlPath -Parent
            if (-not (Test-Path $codexDir)) { New-Item -ItemType Directory -Path $codexDir -Force | Out-Null }

            $escapedVenvPy = $venvPy.Replace('\', '\\')
            $escapedServerPy = $serverPy.Replace('\', '\\')
            $escapedAcadExe = $acadExe.Replace('\', '\\')
            $escapedTargetDir = $targetDir.Replace('\', '\\')

            $tomlSnippet = "`n[mcp_servers.autocad_2021]`ncommand = `"$escapedVenvPy`"`nargs = [`"$escapedServerPy`"]`n"
            $tomlEnv = "env = { ACAD_CONSOLE_PATH = `"$escapedAcadExe`", AGENTE_ROOT = `"$escapedTargetDir`""
            if (-not [string]::IsNullOrWhiteSpace($lispNetwork)) {
                $escapedLisp = $lispNetwork.Replace('\', '\\')
                $tomlEnv += ", ACAD_EXTRA_LISP_DIRS = `"$escapedLisp`""
            }
            $tomlEnv += " }`n"
            $tomlSnippet += $tomlEnv

            $existingToml = if (Test-Path $codexTomlPath) { [System.IO.File]::ReadAllText($codexTomlPath) } else { "" }
            if ($existingToml -match '(?ms)\[mcp_servers\.autocad_2021\].*?(?=(\r?\n\[|$))') {
                $updatedToml = [regex]::Replace($existingToml, '(?ms)\[mcp_servers\.autocad_2021\].*?(?=(\r?\n\[|$))', [System.Text.RegularExpressions.MatchEvaluator]{ $tomlSnippet.Trim() })
            } else {
                $updatedToml = $existingToml + $tomlSnippet
            }
            [System.IO.File]::WriteAllText($codexTomlPath, $updatedToml, [System.Text.UTF8Encoding]::new($false))
        }

        # 3. Claude Desktop
        if ($chkClaude.Checked) {
            $claudeJsonPath = [System.IO.Path]::Combine($env:APPDATA, "Claude\claude_desktop_config.json")
            $claudeDir = Split-Path $claudeJsonPath -Parent
            if (Test-Path (Split-Path $claudeDir -Parent)) {
                New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
                $cCfg = $null
                if (Test-Path $claudeJsonPath) {
                    try {
                        $rawClaude = Get-Content $claudeJsonPath -Raw
                        if (-not [string]::IsNullOrWhiteSpace($rawClaude)) {
                            $cCfg = $rawClaude | ConvertFrom-Json
                        }
                    } catch {}
                }
                if (-not $cCfg) {
                    $cCfg = [PSCustomObject]@{ "mcpServers" = [PSCustomObject]@{} }
                }
                if (-not $cCfg.psobject.properties['mcpServers']) {
                    $cCfg | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{}) -Force
                }
                if ($cCfg.mcpServers.psobject.properties['autocad-2021']) {
                    $cCfg.mcpServers.'autocad-2021' = $srvEntry
                } else {
                    $cCfg.mcpServers | Add-Member -MemberType NoteProperty -Name 'autocad-2021' -Value $srvEntry -Force
                }
                $cCfgJson = $cCfg | ConvertTo-Json -Depth 10
                [System.IO.File]::WriteAllText($claudeJsonPath, $cCfgJson, [System.Text.UTF8Encoding]::new($false))
            }
        }

        $progressBar.Value = 100
        $lblStatusBottom.Text = "¡Instalación y configuración completadas con éxito!"
        $lblStatusBottom.ForeColor = [System.Drawing.Color]::DarkGreen

        [System.Windows.Forms.MessageBox]::Show(
            "El Agente de AutoCAD 2021 MCP v1.4.9 se instaló y configuró correctamente en:`n`n$targetDir`n`nLas IDEs seleccionadas ya están vinculadas.",
            "Instalación Exitosa",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        $form.Close()

    } catch {
        $progressBar.Visible = $false
        $lblStatusBottom.Text = "Ocurrió un error durante la instalación."
        $lblStatusBottom.ForeColor = [System.Drawing.Color]::Firebrick
        $btnInstall.Enabled = $true
        $btnCancel.Enabled = $true
        [System.Windows.Forms.MessageBox]::Show("Error durante la instalación:`n`n$_", "Fallo de Instalación", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$form.ShowDialog() | Out-Null
