#!/usr/bin/env python3
"""验证并生成可复现的 DST 模组包；运行期没有 Python/Node 依赖。"""
import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def files():
    # 白名单避免把研究源码、测试存档、依赖、凭据或本地日志一起打包。
    selected = [ROOT / name for name in ("modinfo.lua", "modmain.lua", "README.md", "README.zh-CN.md", "LICENSE", "THIRD_PARTY_NOTICES.md")]
    selected += sorted((ROOT / "scripts").rglob("*.lua"))
    selected += sorted((ROOT / "docs").glob("*.md"))
    selected += sorted((ROOT / "docs" / "evidence").glob("*.txt"))
    selected += sorted((ROOT / "docs" / "evidence").glob("*.json"))
    return sorted(selected)


def check(selected):
    compiler = shutil.which("luac5.1") or shutil.which("luac")
    if not compiler:
        raise SystemExit("Install Lua 5.1 (luac5.1) before packaging")
    for path in selected:
        if path.is_symlink() or not path.is_file():
            raise SystemExit(f"Missing file or unexpected symlink: {path.relative_to(ROOT)}")
        text = path.read_text(encoding="utf-8")
        if "\x00" in text:
            raise SystemExit(f"NUL in text file: {path.name}")
        if path.suffix == ".lua":
            subprocess.run([compiler, "-p", str(path)], check=True)
    if len(selected) < 20:
        raise SystemExit("Incomplete runtime package")
    print(f"Package check: {len(selected)} UTF-8 files; Lua syntax valid")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--out-dir", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    selected = files()
    check(selected)
    if args.check:
        return
    args.out_dir.mkdir(parents=True, exist_ok=True)
    output = args.out_dir / "Wildwise-0.2.1.zip"
    # 固定时间、权限与排序；相同源码在本地和 CI 得到同一归档内容。
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in selected:
            entry = zipfile.ZipInfo("Wildwise/" + path.relative_to(ROOT).as_posix(), (2026, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".zip.sha256").write_text(f"{digest}  {output.name}\n", encoding="utf-8")
    print(f"Created {output} ({output.stat().st_size} bytes)\nSHA-256 {digest}")


if __name__ == "__main__":
    main()
