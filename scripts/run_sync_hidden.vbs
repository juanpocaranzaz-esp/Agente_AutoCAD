Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(scriptDir, "sync_from_github.ps1")
cmd = "powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -File """ & psScript & """"
WshShell.Run cmd, 0, False
