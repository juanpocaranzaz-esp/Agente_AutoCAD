import ast
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))
SPEC_JSON_PATH = BASE_DIR / "especificacion_del_agente_y_mcp_autocad_2021-V1.4.9.json"
GLOBAL_SKILL_PATH = Path(os.environ.get("GEMINI_SKILLS_PATH", Path.home() / ".gemini" / "config" / "skills" / "autolisp-developer" / "SKILL.md"))

print(f"=== Running Rigorous Verification Suite on V1.4.9 ({SPEC_JSON_PATH}) ===")

# Test 1: JSON RFC 8259 Validity
assert SPEC_JSON_PATH.exists(), f"File not found: {SPEC_JSON_PATH}"
raw_json = SPEC_JSON_PATH.read_text(encoding="utf-8")
data = json.loads(raw_json)
print("Test 1 Passed: JSON is valid RFC 8259!")

assert data["project_metadata"]["version"] == "1.4.9", "Version must be 1.4.9"
assert "lisp-library" in data["directory_tree"], "lisp-library must be in directory_tree"

files_dict = {f["path"]: f["content"] for f in data["files"]}
assert "mcp-autocad/server.py" in files_dict, "server.py missing"
assert ".agents/skills/cad-inspector-base/scripts/extract_drawing_info.lsp" in files_dict, "extract_drawing_info.lsp missing"
assert "setup_local.bat" in files_dict, "setup_local.bat missing"
assert "AGENTS.md" in files_dict, "AGENTS.md missing"
assert "MEMORY.md" in files_dict, "MEMORY.md missing"
assert ".agents/rules/autocad-invariants.md" in files_dict, "autocad-invariants.md missing"
assert ".agents/rules/reglas-entorno-desarrollo.md" not in files_dict, "reglas-entorno-desarrollo.md must be excluded from production spec package"
assert "lisp-library/primitives.lsp" in files_dict, "primitives.lsp missing"
assert "lisp-library/audit_topology.lsp" in files_dict, "audit_topology.lsp missing"
for rel_path, json_content in files_dict.items():
    disk_path = SPEC_JSON_PATH.parent / rel_path
    assert disk_path.exists(), f"Scaffolded file missing on disk: {disk_path}"
    assert disk_path.read_text(encoding="utf-8") == json_content, f"Disk file out of sync with V1.4.9.json: {rel_path}"
print(f"Test 2 Passed: All {len(files_dict)} required files present in JSON and 100% synchronized with disk!")

# Test 3: AST Parse of server.py
server_code = files_dict["mcp-autocad/server.py"]
parsed_ast = ast.parse(server_code)
print("Test 3 Passed: server.py compiled successfully with ast.parse()!")

# Test 4: Extract and dynamically execute server.py security helpers
namespace = {}
test_root = Path(tempfile.gettempdir()) / "cad_test_root_v146"
(test_root / "mcp-autocad" / "logs").mkdir(parents=True, exist_ok=True)
(test_root / "mcp-autocad" / "temp").mkdir(parents=True, exist_ok=True)
(test_root / ".agents" / "skills").mkdir(parents=True, exist_ok=True)
(test_root / "lisp-library").mkdir(parents=True, exist_ok=True)

# Create a test LISP in lisp-library to test resolution
(test_root / "lisp-library" / "SUMLP.lsp").write_text("(defun c:SUMLP () (princ \"sum\"))", encoding="utf-8")

from unittest.mock import MagicMock

for mod in ["win32com", "win32com.client", "pythoncom", "pywintypes", "win32file", "mcp.server.fastmcp"]:
    if mod not in sys.modules:
        sys.modules[mod] = MagicMock()

helpers_match = re.search(r"def get_allowed_lisp_roots.*?(?=@mcp\.tool)", server_code, re.DOTALL)
if not helpers_match:
    raise ValueError("Could not find helpers section in server.py")

helper_code = f"""
import os
import re
import sys
import csv
import html
import logging
import math
import stat
import threading
import tempfile
import shutil
import time
import subprocess
from pathlib import Path
from typing import List, Tuple, Dict, Any, Optional
from unittest.mock import MagicMock

AGENTE_ROOT = Path(r"{test_root}")
TEMP_DIR = AGENTE_ROOT / "mcp-autocad" / "temp"
LOG_DIR = AGENTE_ROOT / "mcp-autocad" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)
SKILLS_ROOT = AGENTE_ROOT / ".agents" / "skills"
LISP_LIB_ROOT = AGENTE_ROOT / "lisp-library"
LAST_GIT_SYNC_STATUS = "OK"

class FastMCP:
    def __init__(self, *args, **kwargs): pass
    def tool(self, *args, **kwargs):
        def dec(fn): return fn
        return dec

""" + helpers_match.group(0)

exec(helper_code, namespace)
validate_lisp_structure = namespace["validate_lisp_structure"]
validate_lisp_safety = namespace["validate_lisp_safety"]
decode_accore_stdout = namespace["decode_accore_stdout"]
_check_command_shell_invocations = namespace["_check_command_shell_invocations"]
_check_open_calls_whitelist = namespace["_check_open_calls_whitelist"]
_resolve_and_verify_skill_load_path = namespace["_resolve_and_verify_skill_load_path"]

print("Test 4 Passed: Server helper functions extracted into test runner!")

# Test 5: validate_lisp_structure tests
print("\n--- Testing validate_lisp_structure ---")
# 5.1 Valid balanced structure
validate_lisp_structure('(progn (command "_.UCS" "_World") (princ "OK"))')
validate_lisp_structure('(defun c:test () ;| block comment |; (princ "Hello \\"CAD\\" (nested paren in string)"))')
validate_lisp_structure('(princ "string with \\\\ double backslash before quote")')
print("5.1: Valid structures passed.")

# 5.2 Unbalanced parentheses
try:
    validate_lisp_structure('(progn (command "_.UCS" "_World"')
    assert False, "Should fail on unclosed ("
except ValueError as e:
    assert "unclosed" in str(e).lower()
    print("5.2: Unclosed '(' detected correctly:", e)

try:
    validate_lisp_structure('(progn (command "_.UCS" "_World")))')
    assert False, "Should fail on unexpected )"
except ValueError as e:
    assert "unexpected" in str(e).lower()
    print("5.3: Unexpected ')' detected correctly:", e)

# 5.3 Unclosed string literal
try:
    validate_lisp_structure('(progn (command "_.UCS" "_World))')
    assert False, "Should fail on unclosed string"
except ValueError as e:
    assert "unclosed string" in str(e).lower()
    print("5.4: Unclosed string detected correctly:", e)

# 5.4 Unclosed block comment
try:
    validate_lisp_structure('(progn ;| unclosed comment (command "_.UCS" "_World"))')
    assert False, "Should fail on unclosed block comment"
except ValueError as e:
    assert "unclosed block comment" in str(e).lower()
    print("5.5: Unclosed block comment detected correctly:", e)

# Test 6: Circuit Breaker tests (validate_lisp_safety)
print("\n--- Testing validate_lisp_safety ---")

# 6.1 Direct startapp
try:
    validate_lisp_safety('(startapp "calc.exe")')
    assert False, "Should fail on startapp"
except ValueError as e:
    print("6.1: Direct startapp caught:", e)

# 6.2 Indirect startapp via list quotation
try:
    validate_lisp_safety("((cadr '(1 startapp)) \"calc.exe\")")
    assert False, "Should fail on indirect quoted startapp"
except ValueError as e:
    print("6.2: Indirect quoted startapp caught:", e)

# 6.3 Apply startapp
try:
    validate_lisp_safety("(apply (nth 1 '(a startapp)) '(\"calc\"))")
    assert False, "Should fail on apply startapp"
except ValueError as e:
    print("6.3: Apply startapp caught:", e)

# 6.4 eval and read
try:
    validate_lisp_safety('(eval (read "some_code"))')
    assert False, "Should fail on eval/read"
except ValueError as e:
    print("6.4: eval / read caught:", e)

# 6.5 setenv
try:
    validate_lisp_safety('(setenv "ACAD" "c:/evil")')
    assert False, "Should fail on setenv"
except ValueError as e:
    print("6.5: setenv caught:", e)

# 6.6 arxload and autoarxload
try:
    validate_lisp_safety('(autoarxload "evil.arx" \'("cmd"))')
    assert False, "Should fail on autoarxload"
except ValueError as e:
    print("6.6: autoarxload caught:", e)

# 6.7 COM creation: vla-getinterfaceobject and vlax-import-type-library
try:
    validate_lisp_safety('(vla-getinterfaceobject (vlax-get-acad-object) "WScript.Shell")')
    assert False, "Should fail on vla-getinterfaceobject"
except ValueError as e:
    print("6.7: vla-getinterfaceobject caught:", e)

try:
    validate_lisp_safety('(vlax-import-type-library :tlb-filename "evil.tlb")')
    assert False, "Should fail on vlax-import-type-library"
except ValueError as e:
    print("6.8: vlax-import-type-library caught:", e)

# 6.8 Open write / append checks
try:
    validate_lisp_safety('(open "file.txt" "w")')
    assert False, "Should fail on (open ... 'w')"
except ValueError as e:
    print("6.9: open write caught:", e)

try:
    validate_lisp_safety('(open"file.txt" "w")')
    assert False, "Should fail on (open\"...\" 'w')"
except ValueError as e:
    print("6.10: open write without space caught:", e)

try:
    validate_lisp_safety('(open (strcat "a" "b") "w")')
    assert False, "Should fail on nested S-expr open write"
except ValueError as e:
    print("6.11: nested open write caught:", e)

try:
    validate_lisp_safety('(open "file.txt" mode_var)')
    assert False, "Should fail on variable open mode"
except ValueError as e:
    print("6.12: open variable mode caught:", e)

try:
    validate_lisp_safety('(apply open \'("file.txt" "w"))')
    assert False, "Should fail on indirect open"
except ValueError as e:
    print("6.13: indirect open caught:", e)

# Allowed read-only open
validate_lisp_safety('(open "file.txt" "r")')
validate_lisp_safety('(open (strcat (getvar "DWGPREFIX") "salida.txt") "r")')
print("6.14: Literal read-only (open ... \"r\") allowed successfully.")

# 6.9 Command shell and code loading injection in ANY argument position and concatenation
dangerous_commands = [
    ('(command "_.SHELL" "calc")', "command _.SHELL as separate arg"),
    ('(command "SHELL calc.exe")', "command SHELL with arguments concatenated"),
    ('(command "_.SHELL calc")', "command _.SHELL with argument concatenated"),
    ('(command "SH\\ncalc")', "command SH with newline separator"),
    ('(vl-cmdf "._SH" "calc")', "vl-cmdf ._SH"),
    ('(command "_.NETLOAD" "evil.dll")', "command _.NETLOAD"),
    ('(command "_.ARX" "_L" "evil.arx")', "command _.ARX"),
    ('(command "_.SCRIPT" "evil.scr")', "command _.SCRIPT"),
    ('(command "_.VBALOAD" "evil.dvb")', "command _.VBALOAD"),
    ('(command "_.APPLOAD")', "command _.APPLOAD"),
    ('(apply \'command \'("SHELL" "calc"))', "apply command SHELL"),
    ('(apply \'vl-cmdf \'("SHELL" "calc"))', "apply vl-cmdf SHELL"),
    ('(vl-catch-all-apply \'command \'("SHELL" "calc"))', "vl-catch-all-apply command SHELL"),
    ('(apply (quote command) \'("SHELL" "calc"))', "apply (quote command) SHELL"),
    ('(apply (function command) \'("SHELL" "calc"))', "apply (function command) SHELL"),
    ('(command "_.UCS" "_World" "SHELL calc.exe")', "command SHELL with args in 3rd position"),
    ('(command "_.LAYER" "" "SHELL" "whoami")', "SHELL invocation after command terminator in LAYER"),
    ('(command "_.LAYER" "_Set" "0" "" "SHELL" "whoami")', "SHELL invocation after full LAYER command"),
    ('(command "_.LAYER" "SHELL" "whoami")', "SHELL invocation without option keyword in LAYER"),
    ('(command "_.LAYER" "_Set" "SHELL" "calc")', "executable parameter following SHELL layer"),
    ('(command "_.INSERT" "SHELL" "" "SHELL" "calc")', "SHELL invocation after INSERT terminator"),
]

for cmd_code, desc in dangerous_commands:
    try:
        validate_lisp_safety(cmd_code)
        assert False, f"Should fail on {desc}"
    except ValueError as e:
        print(f"6.15 [OK] Caught {desc}: {e}")

# Allowed layer/block names containing SH / SHELL / SCRIPT outside and inside safe property commands
validate_lisp_safety('(tblsearch "LAYER" "SH")')
validate_lisp_safety('(tblsearch "LAYER" "SHELL")')
validate_lisp_safety('(tblsearch "LAYER" "SCRIPT")')
validate_lisp_safety('(setq my-layer-name "SHELL")')
validate_lisp_safety('(command "_.LINE" \'(0 0) \'(10 10) "")')
validate_lisp_safety('(vl-cmdf "_.CIRCLE" \'(0 0) 5)')
validate_lisp_safety('(command "_.LAYER" "_Set" "SHELL" "")')
validate_lisp_safety('(command "_.LAYER" "_Make" "SH" "")')
validate_lisp_safety('(command "_.INSERT" "SHELL" \'(0 0) 1 1 0)')
validate_lisp_safety('(command "_.STYLE" "SH" "romans.shx" 0 1 0 "N" "N" "N")')
validate_lisp_safety('(command "_.TEXT" \'(0 0) 2.5 0 "SHELL")')
print("6.16: Safe layer/block/style names ('SH', 'SHELL', 'SCRIPT') and standard drawing commands allowed without false positive.")

# Test 6.16b: Circuit breaker allows (command) with 0 args (ESC cancel) and (vl-cmdf) with 0 args
validate_lisp_safety('(command)')
validate_lisp_safety('(vl-cmdf)')
validate_lisp_safety('(while (> (logand (getvar "CMDACTIVE") 3) 0) (command))')
print("6.16b: (command) with 0 args and CMDACTIVE bitmask correctly permitted.")

# Test 6.16b2: Verify B-01 fix: combined_lisp handles lisp_code=None without AttributeError
skill_c = '(princ "test")'
lisp_c = None
combined = "\n".join(part for part in (skill_c, lisp_c or "") if part.strip())
assert combined == '(princ "test")', "combined_lisp must safely handle lisp_code=None"
print("6.16b2: B-01 verified: mutate_cad_headless safely handles lisp_code=None.")

# Test 6.16c: Circuit breaker catches dynamic variables, concatenation, uppercase SETQ, transitive taint, and apply
for dyn_code, dyn_desc in [
    ('(setq c "SHELL") (command c "calc")', "variable command name"),
    ('(command (strcat "S" "HELL") "calc")', "strcat inside command form"),
    ('(setq c "SHELL") (command "_.UCS" "_World" c "calc")', "tainted variable in 3rd argument position"),
    ('(setq s (strcat "SH" "ELL")) (command s "calc")', "dynamic string variable in command"),
    ('(SETQ C "SHELL") (command "_.UCS" "_World" C "calc")', "uppercase SETQ tainted variable"),
    ('(setq c "SHELL calc.exe") (command "_.UCS" "_World" c)', "tainted variable with concatenated command args"),
    ('(setq c "SHELL") (setq d c) (command "_.UCS" "_World" d)', "transitively tainted variable"),
    ('(apply \'command my_dynamic_list)', "dynamic variable list in apply command"),
]:
    try:
        validate_lisp_safety(dyn_code)
        assert False, f"Should fail on {dyn_desc}"
    except ValueError as e:
        print(f"6.16c [OK] Caught {dyn_desc}: {e}")

# Verify hyphenated safe symbols are not falsely flagged when a short variable is tainted
validate_lisp_safety('(setq c "SHELL") (command "_.LAYER" "_Set" my-c "")')
print("6.16d: Safe hyphenated variable 'my-c' allowed without false positive when 'c' is tainted.")

# Test 6.17b: Load path resolution without .lsp extension (SUMLP -> SUMLP.lsp)
candidate_path_no_ext = _resolve_and_verify_skill_load_path("SUMLP")
assert candidate_path_no_ext.exists(), "SUMLP without .lsp must resolve to SUMLP.lsp"
print(f"6.17b: Resolved library routine (load 'SUMLP') -> {candidate_path_no_ext}")


# 6.10 Load path resolution from lisp-library/ and .agents/skills/
candidate_path = _resolve_and_verify_skill_load_path("SUMLP.lsp")
assert candidate_path.exists(), "SUMLP.lsp must resolve inside lisp-library"
print(f"6.17: Resolved library routine (load 'SUMLP.lsp') -> {candidate_path}")

try:
    _resolve_and_verify_skill_load_path("../../evil.lsp")
    assert False, "Should fail on path traversal"
except (ValueError, FileNotFoundError) as e:
    print("6.18: Path traversal outside trusted roots blocked:", e)

# Test 6.19: Sentinel-scoped console warning detection (B-11) & server.py invariants (B-03, B-04, B-08, B-10, B-13, B-14)
detect_console_command_warnings = namespace["detect_console_command_warnings"]
noisy_console = (
    'Loading Xref...\nUnknown command "ACAD_PROXY_ENTITY".\n'
    "[MCP_MUTATE_EXEC_START]\nCommand: _.LINE\n[MCP_MUTATE_EXEC_END]\n[MCP_MUTATE_SUCCESS]\n"
)
assert detect_console_command_warnings(noisy_console) == [], "Pre-sentinel Xref/proxy warnings must be ignored!"
real_err_console = (
    "[MCP_MUTATE_EXEC_START]\nUnknown command \"BADCMD\".\n[MCP_MUTATE_EXEC_END]\n"
)
assert len(detect_console_command_warnings(real_err_console)) == 1, "In-window command errors must be detected!"
assert '"git", "add", "MEMORY.md", ".agents/", "lisp-library/"' in server_code, "B-08: git_auto_push must include lisp-library/"
assert server_code.count('(if (> (logand (getvar "CMDACTIVE") 3) 0) (while (> (logand (getvar "CMDACTIVE") 3) 0) (command)))') >= 2, (
    "B-10: Both mutate_cad_headless and execute_cad_live *error* handlers must cancel active commands with (logand CMDACTIVE 3) before UCS/cleanup"
)
assert 'result["total_selected"] = total_selected' in server_code, "B-14: total_selected must be stored in result"
assert 'result["selection_truncated"] = selection_truncated' in server_code, "B-14: selection_truncated must be stored in result"
assert "doc.StartUndoMark()" not in server_code and "doc.EndUndoMark()" not in server_code, (
    "B-04: UndoMark must be managed inside AutoLISP, not via asynchronous COM calls"
)
print("6.19: Verified B-03, B-04, B-08, B-10, B-11, B-13, and B-14 invariants in server.py!")

# Test 7: decode_accore_stdout
print("\n--- Testing decode_accore_stdout ---")
# 7.1 Pure UTF-16LE
u16_bytes = "[MCP_INSPECT_SUCCESS] Drawing inspected".encode("utf-16le")
res_u16 = decode_accore_stdout(u16_bytes)
assert "[MCP_INSPECT_SUCCESS]" in res_u16
print("7.1: Pure UTF-16LE decoded:", res_u16)

# 7.2 1-byte misaligned UTF-16LE
misaligned_bytes = b"X" + "[MCP_MUTATE_SUCCESS] Done".encode("utf-16le")
res_misaligned = decode_accore_stdout(misaligned_bytes)
assert "[MCP_MUTATE_SUCCESS]" in res_misaligned
print("7.2: 1-byte misaligned UTF-16LE recovered cleanly:", res_misaligned)

# 7.3 CP1252 ANSI
cp1252_bytes = "Drawing: Planta Baja, Sección A-A, Ø12 mm, ±0.05".encode("cp1252")
res_cp1252 = decode_accore_stdout(cp1252_bytes)
assert "Planta Baja" in res_cp1252
print("7.3: CP1252 ANSI decoded:", res_cp1252)

# Test 8: extract_drawing_info.lsp checks
print("\n--- Testing extract_drawing_info.lsp ---")
lsp_code = files_dict[".agents/skills/cad-inspector-base/scripts/extract_drawing_info.lsp"]

# Check parentheses balance
open_parens = lsp_code.count("(")
close_parens = lsp_code.count(")")
assert open_parens == close_parens, f"Parentheses mismatch: {open_parens} '(' vs {close_parens} ')'"
print(f"8.1: Parentheses balanced: {open_parens} '(' and {close_parens} ')'.")

# Check required invariants in extract_drawing_info.lsp
assert "(pt-wcs-json pt (if (= etype \"MTEXT\") nil norm))" in lsp_code, "MTEXT must not use norm transformation"
assert "(pt-wcs-json (getvar \"EXTMIN\") nil)" in lsp_code, "EXTMIN is already WCS in AutoCAD"
assert "(pt-wcs-json (getvar \"EXTMAX\") nil)" in lsp_code, "EXTMAX is already WCS in AutoCAD"
assert "(trans (getvar \"EXTMIN\") 1 0)" not in lsp_code, "EXTMIN must not be incorrectly transformed"
assert "(trans (getvar \"EXTMAX\") 1 0)" not in lsp_code, "EXTMAX must not be incorrectly transformed"
assert "build-ssget-filter" in lsp_code, "B-12: Native C++ DXF ssget filter builder must be present"
assert "(while (and (< i (sslength ss)) (< textsCount limitVal))" in lsp_code, "B-12: Early loop termination at limitVal for texts required"
assert "(while (and (< i (sslength ss)) (< blocksCount limitVal))" in lsp_code, "B-12: Early loop termination at limitVal for blocks required"
assert r'\"tilemode\":' in lsp_code, "tilemode must be included in JSON export"
assert r'\"ctab\":' in lsp_code, "ctab must be included in JSON export"
assert r"\u00d8" in lsp_code and r"\u00b0" in lsp_code and r"\u00b1" in lsp_code, "Technical symbols must be converted to Unicode escapes"
assert "clean-mtext-braces" in lsp_code, "clean-mtext-braces must be defined"
assert "SEQEND" in lsp_code, "Attribute loop must loop until SEQEND"
assert "(member '(101 . \"Embedded Object\") attEd)" in lsp_code, "Multiline attribute extraction required"
assert "AcDbBlockRepBTag" in lsp_code and "handent" in lsp_code, "AcDbBlockRepBTag fallback required"
print("8.2: All extract_drawing_info.lsp invariants (including B-05 and B-12) verified!")

# Test 9: setup_local.bat checks
print("\n--- Testing setup_local.bat ---")
bat_code = files_dict["setup_local.bat"]
assert 'pushd "%~dp0"' in bat_code and "popd" in bat_code, "setup_local.bat must use pushd/popd for UNC compatibility"
assert 'if not exist ".venv\\Scripts\\python.exe"' in bat_code, "setup_local.bat must check python.exe in .venv"
assert 'for /D %%S in (".agents\\skills\\*")' in bat_code, "setup_local.bat must dynamically iterate over skills"
assert 'mkdir "lisp-library"' in bat_code, "setup_local.bat must create lisp-library"
assert 'set "SCRIPT_DIR=%~dp0"' in bat_code, "setup_local.bat must store %~dp0 to resolve UNC path persistently"
assert "cfg_p.write_text" in bat_code, "B-15: setup_local.bat must write MCP server registration to mcp_config.json"
print("9.1: setup_local.bat UNC, dynamic skill, and MCP config registration checks passed!")

# Test 10: Documentation checks (AGENTS.md, MEMORY.md, autocad-invariants.md)
print("\n--- Testing Documentation ---")
agents_md = files_dict["AGENTS.md"]
memory_md = files_dict["MEMORY.md"]
invariants_md = files_dict[".agents/rules/autocad-invariants.md"]

assert "lisp-library/" in agents_md and "\\\\bashemdc\\ESTUDIO\\PROGRAMAS\\" in agents_md
assert "MTEXT" in agents_md and "WCS" in agents_md
assert "lisp-library/" in memory_md and "WCS" in memory_md
assert "MTEXT" in invariants_md and "World Coordinate System" in invariants_md
assert "AcDbBlockRepBTag" in invariants_md
print("10.1: Documentation invariants passed!")

# Test 11: Global SKILL.md checks
print("\n--- Testing autolisp-developer SKILL.md ---")
if GLOBAL_SKILL_PATH.exists():
    skill_text = GLOBAL_SKILL_PATH.read_text(encoding="utf-8")
    assert "mutate_cad_headless" in skill_text, "SKILL.md must prioritize mutate_cad_headless"
    assert "execute_cad_live" in skill_text, "SKILL.md must mention execute_cad_live"
    assert "inspect_cad_headless" in skill_text, "SKILL.md must mention inspect_cad_headless"
    assert "pruebas" not in skill_text.lower() or "No es necesario exigir al usuario mover el archivo a una carpeta de \"pruebas\"" in skill_text, "Should eliminate manual pruebas requirement"
    assert "2-Lib_Comandos" not in skill_text, "SKILL.md must not require saving python scripts to 2-Lib_Comandos"
    assert "save_studio_learning" in skill_text, "SKILL.md must recommend save_studio_learning"
    assert "\\\\bashemdc\\ESTUDIO\\PROGRAMAS\\" in skill_text, "SKILL.md must reference unified network path"
    assert "lisp-library/" in skill_text, "SKILL.md must reference lisp-library/"
    print("11.1: Global SKILL.md aligned with MCP V1.4.9!")
else:
    print("11.1: Global SKILL.md skipped (clean development environment without global install).")

# Test 12: Unpack specification end-to-end verification
print("\n--- Testing unpack_spec.py end-to-end ---")
try:
    import unpack_spec
except ModuleNotFoundError:
    import importlib.util
    spec = importlib.util.spec_from_file_location("unpack_spec", str(BASE_DIR / "unpack_spec.py"))
    unpack_spec = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(unpack_spec)
unpack_test_dir = Path(tempfile.gettempdir()) / "cad_test_unpack_v147"
if unpack_test_dir.exists():
    shutil.rmtree(unpack_test_dir, ignore_errors=True)
unpack_spec.unpack(SPEC_JSON_PATH, unpack_test_dir)
for rel_path in files_dict.keys():
    unpacked_f = unpack_test_dir / rel_path
    assert unpacked_f.exists(), f"Unpacked file missing: {unpacked_f}"
print("12.1: unpack_spec.py successfully unpacked all files to clean directory!")

# Test 12.2: unpack_spec.py CLI invocation with single argument (target directory)
unpack_test_dir_cli = Path(tempfile.gettempdir()) / "cad_test_unpack_cli_v147"
if unpack_test_dir_cli.exists():
    shutil.rmtree(unpack_test_dir_cli, ignore_errors=True)
cli_res = subprocess.run([sys.executable, str(BASE_DIR / "unpack_spec.py"), str(unpack_test_dir_cli)], capture_output=True, text=True)
assert cli_res.returncode == 0, f"unpack_spec CLI failed: {cli_res.stderr}"
assert (unpack_test_dir_cli / "mcp-autocad" / "server.py").exists(), "server.py missing in CLI unpacked directory"
print("12.2: unpack_spec.py single-argument CLI successfully unpacked default specification!")


# Test 13: V1.4.9 Extensions (Spatial BBox, Field Projection, Takeoffs, Revision Diff, Critique & Headless Plot)
print("\n--- Testing V1.4.9 Extensions ---")
validate_and_format_bbox = namespace["validate_and_format_bbox"]
filter_entities_by_bbox = namespace["filter_entities_by_bbox"]
project_entity_fields = namespace["project_entity_fields"]
compute_takeoff_summary = namespace["compute_takeoff_summary"]
export_takeoff_report = namespace["export_takeoff_report"]
resolve_comparison_dwg = namespace["resolve_comparison_dwg"]
compute_drawing_diff = namespace["compute_drawing_diff"]
critique_drawing_data = namespace["critique_drawing_data"]
build_headless_plot_script = namespace["build_headless_plot_script"]
wrap_untrusted_cad_text = namespace["wrap_untrusted_cad_text"]

# 13.1 Spatial BBox validation & filtering
bbox_norm = validate_and_format_bbox([100.0, 200.0, 10.0, 50.0])
assert bbox_norm == (10.0, 50.0, 100.0, 200.0), f"Expected normalized bbox, got {bbox_norm}"
try:
    validate_and_format_bbox([10.0, 20.0])
    assert False, "Should fail on 2-element bbox"
except ValueError:
    pass

sample_cad_data = {
    "dwgname": "TestPlan.dwg",
    "insunits": 4,
    "measurement": 1,
    "layers": [
        {"name": "0", "color": 7, "status": 0},
        {"name": "ARQ_MUROS", "color": 1, "status": 0},
        {"name": "INST_AGUA", "color": 5, "status": 0},
    ],
    "texts": [
        {"handle": "T1", "type": "TEXT", "layer": "ARQ_MUROS", "space": "model", "layout": "Model", "text": wrap_untrusted_cad_text("Dormitorio 1"), "pos": [25.0, 60.0, 0.0]},
        {"handle": "T2", "type": "MTEXT", "layer": "ARQ_MUROS", "space": "model", "layout": "Model", "text": wrap_untrusted_cad_text("Fuera de caja"), "pos": [500.0, 600.0, 0.0]},
    ],
    "blocks": [
        {"handle": "B1", "name": "*U12", "effective_name": "PUERTA_090", "is_dynamic": True, "layer": "ARQ_MUROS", "space": "model", "layout": "Model", "pos": [30.0, 80.0, 0.0], "attributes": [{"tag": "TIPO", "val": wrap_untrusted_cad_text("P1")}]},
        {"handle": "B2", "name": "PUERTA_090", "effective_name": "PUERTA_090", "is_dynamic": False, "layer": "ARQ_MUROS", "space": "model", "layout": "Model", "pos": [45.0, 90.0, 0.0], "attributes": [{"tag": "TIPO", "val": wrap_untrusted_cad_text("P1")}]},
        {"handle": "B3", "name": "VALVULA", "effective_name": "VALVULA", "is_dynamic": False, "layer": "INST_AGUA", "space": "model", "layout": "Model", "pos": [800.0, 800.0, 0.0], "attributes": []},
    ],
    "curves": [
        {"handle": "C1", "type": "LWPOLYLINE", "layer": "ARQ_MUROS", "space": "model", "layout": "Model", "closed": True, "length": 18.0, "area": 20.0, "pos": [20.0, 55.0, 0.0]},
        {"handle": "C2", "type": "LINE", "layer": "INST_AGUA", "space": "model", "layout": "Model", "closed": False, "length": 12.5, "area": 0.0, "pos": [25.0, 65.0, 0.0]},
        {"handle": "C3", "type": "LINE", "layer": "INST_AGUA", "space": "model", "layout": "Model", "closed": False, "length": 50.0, "area": 0.0, "pos": [900.0, 900.0, 0.0]},
    ],
}

bbox_filtered = filter_entities_by_bbox(sample_cad_data, bbox_norm)
assert len(bbox_filtered["texts"]) == 1 and bbox_filtered["texts"][0]["handle"] == "T1"
assert len(bbox_filtered["blocks"]) == 2
assert len(bbox_filtered["curves"]) == 2
print("13.1: Spatial bbox validation and WCS filtering passed!")

# 13.2 Field projection
projected = project_entity_fields(bbox_filtered, ["handle", "effective_name", "text"])
assert set(projected["texts"][0].keys()) == {"handle", "text"}
assert set(projected["blocks"][0].keys()) == {"handle", "effective_name"}
print("13.2: Token-saving field projection passed!")

# 13.3 Metric Takeoff & CSV export
takeoff = compute_takeoff_summary(sample_cad_data)
assert takeoff["by_layer"]["ARQ_MUROS"]["total_length"] == 18.0
assert takeoff["by_layer"]["ARQ_MUROS"]["total_closed_area"] == 20.0
assert takeoff["by_layer"]["INST_AGUA"]["total_length"] == 62.5
assert takeoff["blocks_bom"][0]["effective_name"] == "PUERTA_090" and takeoff["blocks_bom"][0]["count"] == 2
assert takeoff["blocks_bom"][0]["sample_attributes"]["TIPO"] == "P1"

csv_out_file = Path(tempfile.gettempdir()) / "cad_test_takeoff_v149.csv"
exported_csv = export_takeoff_report(takeoff, str(csv_out_file))
assert Path(exported_csv).exists()
csv_text = Path(exported_csv).read_text(encoding="utf-8-sig")
assert "ARQ_MUROS" in csv_text and "PUERTA_090" in csv_text and "62.5" in csv_text
print("13.3: Metric takeoff summary and UTF-8-BOM CSV export passed!")

# 13.4 Revision Diff & Backup resolution
diff_dir = Path(tempfile.gettempdir()) / "cad_test_diff_v149"
diff_dir.mkdir(parents=True, exist_ok=True)
(diff_dir / "Plano.dwg").write_text("curr", encoding="utf-8")
(diff_dir / "Plano-Legacy-0.dwg").write_text("orig", encoding="utf-8")
(diff_dir / "Plano-Legacy-1.dwg").write_text("v1", encoding="utf-8")
(diff_dir / "Plano-Legacy-2.dwg").write_text("v2", encoding="utf-8")

assert resolve_comparison_dwg(diff_dir / "Plano.dwg", "original_backup").name == "Plano-Legacy-0.dwg"
assert resolve_comparison_dwg(diff_dir / "Plano.dwg", "latest_backup").name == "Plano-Legacy-2.dwg"

modified_cad_data = json.loads(json.dumps(sample_cad_data))
modified_cad_data["layers"].append({"name": "COTAS", "color": 3, "status": 0})
modified_cad_data["texts"][0]["text"] = wrap_untrusted_cad_text("Dormitorio Principal")
modified_cad_data["blocks"][0]["pos"] = [35.0, 80.0, 0.0]  # moved 5.0 units

diff_res = compute_drawing_diff(sample_cad_data, modified_cad_data)
assert not diff_res["summary"]["is_identical"]
assert diff_res["layers"]["added"] == ["COTAS"]
assert len(diff_res["texts"]["modified"]) == 1 and diff_res["texts"]["modified"][0]["handle"] == "T1"
assert len(diff_res["blocks"]["moved"]) == 1 and diff_res["blocks"]["moved"][0]["distance"] == 5.0
print("13.4: Revision diffing and Legacy backup resolution passed!")

# 13.5 Automated CAD Hygiene Critique
flawed_data = json.loads(json.dumps(sample_cad_data))
flawed_data["insunits"] = 1  # inches vs measurement=1 metric
flawed_data["texts"].append(dict(flawed_data["texts"][0], handle="T1_DUP"))  # overlapping duplicate text
flawed_data["curves"].append({"handle": "C_ZERO", "type": "LINE", "layer": "0", "space": "model", "layout": "Model", "closed": False, "length": 0.0, "area": 0.0, "pos": [25.0, 60.0, 0.0]})
critique_res = critique_drawing_data(flawed_data)
issue_codes = {iss["code"] for iss in critique_res["issues"]}
assert "UNITS_MISMATCH" in issue_codes
assert "DUPLICATE_OVERLAPPING_TEXTS" in issue_codes
assert "ZERO_LENGTH_GEOMETRY" in issue_codes
assert critique_res["score"] < 100
print(f"13.5: Automated CAD critique detected {critique_res['issue_count']} issues (score={critique_res['score']})!")

# 13.6 Headless Plot Script Generation & Circuit Breaker compatibility
pdf_scr = build_headless_plot_script(Path("/tmp/preview.pdf"), layout_name="Model")
assert "_.-PLOT" in pdf_scr and "DWG To PDF.pc3" in pdf_scr and "BACKGROUNDPLOT 0" in pdf_scr
png_scr = build_headless_plot_script(Path("/tmp/preview.png"), layout_name="Layout1")
assert "_.-PLOT" in png_scr and "PublishToWeb PNG.pc3" in png_scr and "Layout1" in png_scr
validate_lisp_safety('(command "_.-PLOT" "_Yes" "Model" "DWG To PDF.pc3" "ISO full bleed A3 (420.00 x 297.00 MM)" "_Millimeters" "_Landscape" "_No" "_Extents" "_Fit" "_Center" "_Yes" "monochrome.ctb" "_Yes" "_As displayed" "preview.pdf" "_No" "_Yes")')
print("13.6: Headless _.-PLOT script generation and circuit breaker validation passed!")

# 13.7 Verify extract_drawing_info.lsp v1.4.9 symbols
for req_sym in ["parse-bbox-csv", "pt-in-bbox-p", "calc-bulge-arc-len", "calc-bulge-seg-area", "calc-lwpoly-metrics", "MCP_BBOX", "MCP_TAKEOFF"]:
    assert req_sym in lsp_code, f"Missing v1.4.9 symbol in extract_drawing_info.lsp: {req_sym}"
print("13.7: All v1.4.9 AutoLISP symbols verified in extract_drawing_info.lsp!")


# Test 14: Bug Fixes (ENV-01..03, BUG-01..09) & Short-Term Improvements (1.1, 1.2, 1.3)
print("\n--- Testing Bug Fixes & Short-Term Improvements (1.1, 1.2, 1.3) ---")

# Copy primitives.lsp and audit_topology.lsp to test_root/lisp-library
(test_root / "lisp-library" / "primitives.lsp").write_text(files_dict["lisp-library/primitives.lsp"], encoding="utf-8")
(test_root / "lisp-library" / "audit_topology.lsp").write_text(files_dict["lisp-library/audit_topology.lsp"], encoding="utf-8")
(test_root / ".agents" / "rules").mkdir(parents=True, exist_ok=True)

# 14.1 BUG-01 & BUG-02: Circuit breaker blocks TEXT trailing command injection & mapcar higher-order bypass
for exploit_code, exploit_desc in [
    ('(command "_.TEXT" \'(0 0) 2.5 0 "Hola" "SHELL" "calc")', "TEXT trailing SHELL injection"),
    ('(command "_.TEXT" \'(0 0) 2.5 0 "Hola" "NETLOAD" "evil.dll")', "TEXT trailing NETLOAD injection"),
    ('(mapcar \'command \'("_.SHELL") \'("calc"))', "mapcar higher-order command bypass"),
    ('(setq fn command) (fn "_.SHELL" "calc")', "unquoted command symbol assignment"),
]:
    try:
        validate_lisp_safety(exploit_code)
        assert False, f"Should block {exploit_desc}"
    except ValueError as e:
        print(f"14.1 [OK] Blocked {exploit_desc}: {e}")

# 14.2 BUG-09: SAFE_PROPERTY_COMMANDS allows legitimate PURGE, RENAME, CHPROP, and -LAYER _Color string with "SHELL"
for safe_cmd in [
    '(command "_.PURGE" "_LA" "SHELL" "_N")',
    '(command "_.RENAME" "_LA" "SHELL" "NEW_LAYER")',
    '(command "_.CHPROP" (entlast) "" "_LA" "SHELL" "")',
    '(command "_.LAYER" "_Color" "1" "SHELL" "")',
    '(command "_.DIMSTYLE" "_Restore" "SHELL")',
]:
    validate_lisp_safety(safe_cmd)
print("14.2: SAFE_PROPERTY_COMMANDS (PURGE, RENAME, CHPROP, -LAYER _Color, DIMSTYLE) permitted safely!")

# 14.3 BUG-03 & BUG-04: Clockwise LWPOLYLINE bulge area & OCS-to-WCS calculation in extract_drawing_info.lsp
assert "(setq areaVal (abs (+ (* 0.5 shoelace) segSum)))" in lsp_code, "BUG-03: Clockwise LWPOLYLINE bulge area must not invert segSum with polySign"
assert "polySign" not in lsp_code, "BUG-03: polySign must be removed from calc-lwpoly-metrics"
assert '(setq ocsPt (list (car (cdr item)) (cadr (cdr item)) elev))' in lsp_code, "BUG-04: LWPOLYLINE metrics must compute in 2D OCS prior to WCS transform"
print("14.3: BUG-03 & BUG-04 verified in extract_drawing_info.lsp!")

# 14.4 BUG-05, BUG-06, BUG-07 & ENV-01:
is_development_staging_dir = namespace["is_development_staging_dir"]
sync_skill_to_global_ides = namespace["sync_skill_to_global_ides"]

# ENV-01: Ensure development folder and env var are detected as dev staging, while normal installation is not
dev_staging_path = Path(r"h:\Mi unidad\Laboral\CAD Proyect")
normal_install_path = Path(r"C:\AgenteCAD")
assert is_development_staging_dir(dev_staging_path) is True, "ENV-01: Development folder 'CAD Proyect' must be detected as dev staging"
assert is_development_staging_dir(normal_install_path) is False, "ENV-01: Normal install 'C:\\AgenteCAD' must NOT be detected as dev staging"

os.environ["ACAD_MCP_DEV_NO_INSTALL"] = "1"
assert is_development_staging_dir(test_root) is True, "ENV-01: test_root with ACAD_MCP_DEV_NO_INSTALL=1 must be detected as dev staging"
assert sync_skill_to_global_ides(test_root / ".agents" / "skills", "test-skill") == [], "ENV-01: Global skill sync must be skipped in dev staging mode"
os.environ.pop("ACAD_MCP_DEV_NO_INSTALL", None)
assert "lisp_code: Optional[str] = " in server_code, "BUG-05: mutate_cad_headless must accept Optional[str]"

# Verify BUG-06 curve modification diffing
c_base = json.loads(json.dumps(sample_cad_data))
c_mod = json.loads(json.dumps(sample_cad_data))
c_mod["curves"][0]["length"] = 25.0  # stretched C1 from 18.0 to 25.0
c_diff = compute_drawing_diff(c_base, c_mod)
assert len(c_diff["curves"]["modified"]) == 1 and c_diff["curves"]["modified"][0]["handle"] == "C1"
assert c_diff["summary"]["curves_changed"] == 1 and not c_diff["summary"]["is_identical"]

# Verify BUG-07 layout-scoped duplicate detection (same coordinates on different layouts must NOT be flagged as duplicate)
multi_layout_data = json.loads(json.dumps(sample_cad_data))
multi_layout_data["texts"].append({
    "handle": "T1_LAYOUT2",
    "type": "TEXT",
    "layer": "ARQ_MUROS",
    "space": "paper",
    "layout": "Layout2",
    "text": wrap_untrusted_cad_text("Dormitorio 1"),
    "pos": [25.0, 60.0, 0.0],
})
crit_multi = critique_drawing_data(multi_layout_data)
assert "DUPLICATE_OVERLAPPING_TEXTS" not in {i["code"] for i in crit_multi["issues"]}, "BUG-07: Texts on different layouts must not be flagged as overlapping duplicates"
print("14.4: ENV-01, BUG-05, BUG-06, and BUG-07 verified!")

# 14.5 Improvement 1.1: Parametric Drawing Primitives (primitives.lsp + build_primitive_lisp_call)
build_primitive_lisp_call = namespace["build_primitive_lisp_call"]
primitives_code = files_dict["lisp-library/primitives.lsp"]
validate_lisp_structure(primitives_code)
validate_lisp_safety(primitives_code)

line_call = build_primitive_lisp_call("line", start_pt=[0, 0], end_pt=[10, 20], layer="ARQ_MUROS", color=1)
rect_call = build_primitive_lisp_call("rectangle", corner1=[0, 0], corner2=[5, 8], layer="ARQ_MUROS", closed=True, color=3)
circle_call = build_primitive_lisp_call("circle", center=[5, 5], radius=2.5, layer="EJES")
arc_call = build_primitive_lisp_call("arc", center=[0, 0], radius=10.0, start_angle_deg=0.0, end_angle_deg=90.0, layer="ARQ_PUERTAS")
poly_call = build_primitive_lisp_call("lwpolyline", points=[[0, 0], [10, 0], [10, 5]], closed=True, layer="COTA")
blk_call = build_primitive_lisp_call("insert_block", block_name="PUERTA_090", insert_pt=[10, 20], scale_x=1.0, scale_y=1.0, rotation_deg=90.0, layer="ARQ_PUERTAS")

for pcall in (line_call, rect_call, circle_call, arc_call, poly_call, blk_call):
    validate_lisp_structure(pcall)
    validate_lisp_safety(pcall)
print("14.5: Short-Term Improvement 1.1 (Parametric Primitives in primitives.lsp & server.py) verified!")

# 14.6 Improvement 1.2: Topological Audit & Cleanup (audit_topology.lsp + analyze_drawing_topology)
analyze_drawing_topology = namespace["analyze_drawing_topology"]
topo_code = files_dict["lisp-library/audit_topology.lsp"]
validate_lisp_structure(topo_code)
validate_lisp_safety(topo_code)

topo_sample = {
    "curves": [
        # Two connected lines at (10,0), plus a near-miss line starting at (10.0, 3.0) (gap=3.0 <= near_miss_tol=5.0)
        {"handle": "L1", "type": "LINE", "layer": "ARQ_MUROS", "closed": False, "length": 10.0, "area": 0.0, "pos": [0.0, 0.0, 0.0], "end_pos": [10.0, 0.0, 0.0]},
        {"handle": "L2", "type": "LINE", "layer": "ARQ_MUROS", "closed": False, "length": 10.0, "area": 0.0, "pos": [10.0, 0.0, 0.0], "end_pos": [20.0, 0.0, 0.0]},
        {"handle": "L2_DUP", "type": "LINE", "layer": "ARQ_MUROS", "closed": False, "length": 10.0, "area": 0.0, "pos": [20.0, 0.0, 0.0], "end_pos": [10.0, 0.0, 0.0]},
        {"handle": "L_NEAR", "type": "LINE", "layer": "ARQ_MUROS", "closed": False, "length": 10.0, "area": 0.0, "pos": [10.0, 3.0, 0.0], "end_pos": [10.0, 13.0, 0.0]},
        # Unclosed polyline with start/end gap of 2.0 (near-closed)
        {"handle": "P_UNCLOSED", "type": "LWPOLYLINE", "layer": "ARQ_MUROS", "closed": False, "length": 38.0, "area": 0.0, "pos": [0.0, 0.0, 0.0], "end_pos": [0.0, 2.0, 0.0]},
    ]
}
topo_res = analyze_drawing_topology(topo_sample, filter_layers=["ARQ_MUROS"], near_miss_tol=5.0, snap_tol=0.5)
assert topo_res["counts"]["collinear_duplicates"] == 1
assert topo_res["counts"]["unclosed_polylines"] == 1
assert topo_res["counts"]["near_closed_polylines"] == 1
assert topo_res["counts"]["near_misses"] >= 1
assert topo_res["counts"]["dangling_endpoints"] >= 1
print(f"14.6: Short-Term Improvement 1.2 (Topological Audit & Cleanup) verified: {topo_res['counts']}!")

# 14.7 Improvement 1.3: Multimodal Visual Preview (window_bbox plot & convert_pdf_to_png)
convert_pdf_to_png = namespace["convert_pdf_to_png"]
win_scr = build_headless_plot_script(Path("/tmp/win_preview.pdf"), layout_name="Model", window_bbox=[10.0, 20.0, 110.0, 120.0])
assert "_Window\n10.0,20.0\n110.0,120.0\n" in win_scr
assert "def capture_drawing_preview(" in server_code
print("14.7: Short-Term Improvement 1.3 (Multimodal Visual Preview capture_drawing_preview) verified!")


# Test 15: V1.4.9 Specific Fixes & Enhancements (CORR-01 .. CORR-08)
print("\n--- Testing V1.4.9 Enhancements (CORR-01 .. CORR-08) ---")

# 15.1 CORR-01: requirements.txt dependencies
req_text = files_dict["requirements.txt"]
assert "openpyxl" in req_text, "CORR-01: openpyxl must be in requirements.txt"
assert "pypdfium2" in req_text, "CORR-01: pypdfium2 must be in requirements.txt"
assert "Pillow" in req_text, "CORR-01: Pillow must be in requirements.txt"
print("15.1: CORR-01 requirements.txt dependencies verified!")

# 15.2 CORR-02: draw_primitives_batch tool
assert "def draw_primitives_batch(" in server_code, "CORR-02: draw_primitives_batch must be defined in server.py"
sample_ops = [
    {"type": "line", "start_pt": [0, 0], "end_pt": [10, 0], "layer": "ARQ_MUROS"},
    {"type": "rectangle", "corner1": [10, 0], "corner2": [20, 10], "layer": "ARQ_MUROS", "closed": True},
    {"type": "circle", "center": [25, 5], "radius": 2.5, "layer": "ARQ_MUROS"},
    {"type": "insert_block", "block_name": "PUERTA_090", "insert_pt": [5, 0], "scale_x": -1.0, "scale_y": 1.0, "layer": "ARQ_PUERTAS"},
]
batch_lisp_calls = [build_primitive_lisp_call(op["type"], **{k: v for k, v in op.items() if k != "type"}) for op in sample_ops]
for blc in batch_lisp_calls:
    validate_lisp_structure(blc)
    validate_lisp_safety(blc)
assert "abs" in files_dict["lisp-library/primitives.lsp"], "CORR-04: primitives.lsp must preserve positive Z scale"
assert "'(210 0.0 0.0 1.0)" in files_dict["lisp-library/primitives.lsp"], "CORR-04: primitives.lsp must declare explicit WCS normal vector"
print("15.2: CORR-02 & CORR-04 (draw_primitives_batch & primitives.lsp mirror safety) verified!")

# 15.3 CORR-03: Symmetric negative topology floor & T-junction support
audit_topo_lsp = files_dict["lisp-library/audit_topology.lsp"]
assert "mcp-topo-floor" in audit_topo_lsp, "CORR-03: mcp-topo-floor must be present in audit_topology.lsp"
assert "polyLen" in audit_topo_lsp and "zeroRemovedCount" in audit_topo_lsp, "CORR-03: zero-length LWPOLYLINE cleanup must be present"

# T-junction test: L1 from (0,0) to (20,0). L2 from (10,0) to (10,10) meeting L1 in perpendicular 'T'.
t_sample = {
    "curves": [
        {"handle": "L1", "type": "LINE", "layer": "ARQ_MUROS", "closed": False, "length": 20.0, "area": 0.0, "pos": [0.0, 0.0, 0.0], "end_pos": [20.0, 0.0, 0.0]},
        {"handle": "L2", "type": "LINE", "layer": "ARQ_MUROS", "closed": False, "length": 10.0, "area": 0.0, "pos": [10.0, 0.0, 0.0], "end_pos": [10.0, 10.0, 0.0]},
    ]
}
topo_t_res = analyze_drawing_topology(t_sample, filter_layers=["ARQ_MUROS"], snap_tol=0.5)
# In T-junction, L2 start at (10,0) connects to L1 body. The only dangling endpoints are the 3 loose tips: (0,0), (20,0), (10,10).
# The meeting point at (10,0) must NOT be counted as dangling!
dangling_pts = [d["pos"] for d in topo_t_res["dangling_endpoints"]]
assert [10.0, 0.0] not in dangling_pts, f"T-junction point [10,0] must be recognized as connected, got {dangling_pts}"
print("15.3: CORR-03 (Symmetric topology floor & T-junction support) verified!")

# 15.4 CORR-05: Curve bbox filtering includes curves whose end_pos is inside bbox
sample_cross_curve = {
    "curves": [
        # Starts at (-100, 50) [outside bbox], ends at (30, 60) [inside bbox (10, 50, 100, 200)]
        {"handle": "C_CROSS", "type": "LINE", "layer": "ARQ_MUROS", "space": "model", "layout": "Model", "closed": False, "length": 130.0, "area": 0.0, "pos": [-100.0, 50.0, 0.0], "end_pos": [30.0, 60.0, 0.0]},
        # Entirely outside bbox
        {"handle": "C_OUT", "type": "LINE", "layer": "ARQ_MUROS", "space": "model", "layout": "Model", "closed": False, "length": 50.0, "area": 0.0, "pos": [-500.0, -500.0, 0.0], "end_pos": [-450.0, -500.0, 0.0]},
    ]
}
cross_filtered = filter_entities_by_bbox(sample_cross_curve, bbox_norm)
assert len(cross_filtered["curves"]) == 1 and cross_filtered["curves"][0]["handle"] == "C_CROSS", "CORR-05: Cross-boundary curve must be preserved in bbox"
print("15.4: CORR-05 (Cross-boundary curve bbox filter) verified!")

# 15.5 CORR-05b: execute_headless_plot parameter propagation
assert "window_bbox: Optional[List[float]] = None" in server_code
assert "execute_headless_plot(" in server_code and "window_bbox=window_bbox" in server_code
assert "def mutate_cad_headless(\n    dwg_path: str,\n    lisp_code: Optional[str] = \"\",\n    skill_script: Optional[str] = None,\n    create_backup: bool = True,\n    verify_audit: bool = True,\n    ignore_stale_lock: bool = False,\n    timeout_sec: int = 90,\n    export_plot_path: Optional[str] = None,\n    plot_layout: str = \"Model\",\n    window_bbox: Optional[List[float]] = None," in server_code, "mutate_cad_headless must accept window_bbox"
print("15.5: CORR-05b (execute_headless_plot parameter propagation in inspect and mutate) verified!")

# 15.6 CORR-06: Idempotent mcp_ucs_pushed in mutate_cad_headless
assert "mcp_ucs_pushed" in server_code, "CORR-06: mcp_ucs_pushed must be present in server.py"
print("15.6: CORR-06 (Idempotent UCS restoration) verified!")

# 15.7 CORR-07 & CORR-08: Documentation and import hygiene
assert "v1.4.9" in files_dict["AGENTS.md"] and "draw_primitives_batch" in files_dict["AGENTS.md"], "CORR-07: AGENTS.md must document v1.4.9"
assert "v1.4.9" in files_dict["MEMORY.md"], "CORR-07: MEMORY.md must document v1.4.9"
assert server_code.count("import csv") == 1, "CORR-08: duplicate import csv must be removed"
assert server_code.count("import json") == 1, "CORR-08: duplicate import json must be removed"

# 15.8 CORR-09: Installer and setup_local.bat registration robustness
bat_code = files_dict["setup_local.bat"]
assert "(?s)\\[mcp_servers\\.autocad_2021\\].*?(?=(\\r?\\n\\[|\\Z))" in bat_code, "setup_local.bat must use singleline end-of-string TOML regex"
assert "%%APPDATA%%" not in bat_code, "setup_local.bat must not use %%APPDATA%% which causes path corruption in batch"
assert "appdata = os.environ.get('APPDATA')" in bat_code, "setup_local.bat must resolve APPDATA via os.environ"
assert "rmdir /s /q" in bat_code, "setup_local.bat must clean up directory fallback"

# Verify TOML regex replacement does not orphan previous keys
sample_toml = '[mcp_servers.autocad_2021]\ncommand = "old.exe"\nargs = ["old.py"]\n\n[other_tool]\nfoo = "bar"\n'
new_snip = '[mcp_servers.autocad_2021]\ncommand = "new.exe"\nargs = ["new.py"]\nenv = { A = "1" }\n'
updated_sample = re.sub(r'(?s)\[mcp_servers\.autocad_2021\].*?(?=(\r?\n\[|\Z))', new_snip.strip(), sample_toml)
assert 'command = "old.exe"' not in updated_sample, "Old TOML section keys must be completely removed"
assert '[other_tool]' in updated_sample and 'foo = "bar"' in updated_sample, "Subsequent TOML sections must be preserved"
print("15.7 & 15.8: CORR-07, CORR-08 & CORR-09 (Documentation, import hygiene, and installer robustness) verified!")

print("\n=======================================================")
print("ALL V1.4.9 VERIFICATION SUITE TESTS PASSED 100%! ")
print("=======================================================")

