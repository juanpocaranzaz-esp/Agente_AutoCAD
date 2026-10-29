"""Packager script for AutoCAD 2021 MCP Agent Specification V2.0.0

Reads the specification, synchronizes all file contents from disk,
updates version metadata, excludes development-only rules and proprietary skills,
and writes especificacion_del_agente_y_mcp_autocad_2021-V2.0.0.json.
"""

import json
from pathlib import Path


def pack() -> None:
    base_dir = Path(__file__).resolve().parent
    v200_path = base_dir / "especificacion_del_agente_y_mcp_autocad_2021-V2.0.0.json"
    v149_path = base_dir / "especificacion_del_agente_y_mcp_autocad_2021-V1.4.9.json"

    source_path = v200_path if v200_path.exists() else v149_path
    if not source_path.exists():
        raise FileNotFoundError(f"Missing specification file: {v200_path} or {v149_path}")

    data = json.loads(source_path.read_text(encoding="utf-8"))

    data["project_metadata"]["version"] = "2.0.0"

    # Ensure docs directory is in directory_tree
    if "directory_tree" in data:
        if "docs" not in data["directory_tree"]:
            data["directory_tree"].append("docs")
    else:
        data["directory_tree"] = ["docs"]

    # Exclude development staging only rule from production package
    files = [
        f for f in data["files"]
        if not f["path"].endswith("reglas-entorno-desarrollo.md")
    ]

    # Ensure files from docs directory are included
    existing_paths = {f["path"].replace("\\", "/") for f in files}
    docs_dir = base_dir / "docs"
    if docs_dir.exists() and docs_dir.is_dir():
        for doc_file in sorted(docs_dir.glob("**/*")):
            if doc_file.is_file():
                rel_posix = doc_file.relative_to(base_dir).as_posix()
                if rel_posix not in existing_paths:
                    files.append({
                        "path": rel_posix,
                        "content": ""
                    })
                    existing_paths.add(rel_posix)

    for f in files:
        rel_path = f["path"]
        disk_file = base_dir / rel_path
        if not disk_file.exists():
            raise FileNotFoundError(f"Missing disk file: {disk_file}")
        f["content"] = disk_file.read_text(encoding="utf-8")

    data["files"] = files

    v200_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] Re-packed {v200_path.name} with {len(data['files'])} files.")


if __name__ == "__main__":
    pack()
