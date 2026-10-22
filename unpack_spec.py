"""
Unpack Specification Utility for AutoCAD 2021 MCP Agent
Scaffolds and unpacks the entire project from a specification JSON file into any target deployment directory.
Usage:
    python unpack_spec.py [path_to_specification.json] [target_directory]
Example:
    python unpack_spec.py especificacion_del_agente_y_mcp_autocad_2021-V1.4.9.json C:\\AgenteCAD
"""

import json
import os
import sys
from pathlib import Path

def unpack(spec_json_path: Path, target_dir: Path) -> None:
    print(f"=== Unpacking AutoCAD MCP Agent Specification ===")
    print(f"Source JSON: {spec_json_path.resolve()}")
    print(f"Target Dir:  {target_dir.resolve()}")

    if not spec_json_path.exists():
        raise FileNotFoundError(f"Specification file not found: {spec_json_path}")

    raw_data = spec_json_path.read_text(encoding="utf-8")
    data = json.loads(raw_data)

    metadata = data.get("project_metadata", {})
    version = metadata.get("version", "unknown")
    print(f"Project: {metadata.get('project_name', 'autocad-agent')} (v{version})")

    # 1. Create directories
    target_dir.mkdir(parents=True, exist_ok=True)
    directory_tree = data.get("directory_tree", [])
    for d in directory_tree:
        dir_path = target_dir / d
        dir_path.mkdir(parents=True, exist_ok=True)

    # 2. Write files
    files = data.get("files", [])
    written_count = 0
    for f in files:
        rel_path = f["path"]
        content = f["content"]
        out_file = target_dir / rel_path
        out_file.parent.mkdir(parents=True, exist_ok=True)
        out_file.write_text(content, encoding="utf-8")
        written_count += 1

    print(f"\n[OK] Successfully unpacked {written_count} files into {target_dir.resolve()}")
    print("\nNext steps on the target machine:")
    print(f"  1. cd /d \"{target_dir.resolve()}\"")
    print(f"  2. run setup_local.bat (to initialize Python venv, install MCP dependencies, and register server)")
    print(f"==================================================")

if __name__ == "__main__":
    current_dir = Path(__file__).resolve().parent
    default_json = None
    for cand in sorted(current_dir.glob("especificacion_del_agente_y_mcp_autocad_2021-V*.json"), reverse=True):
        default_json = cand
        break

    if len(sys.argv) > 2:
        json_arg = Path(sys.argv[1])
        target_arg = Path(sys.argv[2])
    elif len(sys.argv) == 2:
        arg1 = sys.argv[1]
        if arg1.lower().endswith(".json") and Path(arg1).is_file():
            json_arg = Path(arg1)
            target_arg = Path.cwd() / "deployed_agent"
        else:
            json_arg = default_json
            target_arg = Path(arg1)
    else:
        json_arg = default_json
        target_arg = Path.cwd() / "deployed_agent"

    if not json_arg or not json_arg.exists():
        print(f"Error: Specification JSON file not found: {json_arg}")
        sys.exit(1)

    unpack(json_arg, target_arg)
