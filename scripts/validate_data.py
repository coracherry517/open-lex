#!/usr/bin/env python3
"""校验 data/ 下所有法条 JSON：Schema 合规 + 来源必填 + 路径唯一 + 日期合理。
用法：python scripts/validate_data.py
依赖：pip install jsonschema
"""
import json
import sys
from datetime import date
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = json.loads((ROOT / "data/schema/statute.schema.json").read_text(encoding="utf-8"))
BANNED_SOURCES = ("pkulaw", "wkinfo", "westlaw", "lexisnexis", "wenshu.court.gov.cn")


def walk(provisions, seen, errors, file):
    for p in provisions:
        if p["path"] in seen:
            errors.append(f"{file}: 重复路径 {p['path']}")
        seen.add(p["path"])
        if p["level"] == "article" and not p.get("text"):
            errors.append(f"{file}: 条文 {p['path']} 缺少原文 text")
        walk(p.get("children", []), seen, errors, file)


def check(file: Path) -> list[str]:
    errors = []
    doc = json.loads(file.read_text(encoding="utf-8"))
    for e in Draft202012Validator(SCHEMA).iter_errors(doc):
        errors.append(f"{file}: {'/'.join(map(str, e.path))} {e.message}")
    if errors:
        return errors

    url = doc["source"]["url"].lower()
    if any(b in url for b in BANNED_SOURCES):
        errors.append(f"{file}: 来源 {url} 在禁止列表中（见 DATA_SOURCES.md）")

    v = doc["version"]
    start = date.fromisoformat(v["effective_from"])
    if v.get("effective_to") and date.fromisoformat(v["effective_to"]) <= start:
        errors.append(f"{file}: effective_to 必须晚于 effective_from")
    if v["status"] == "repealed" and not v.get("effective_to"):
        errors.append(f"{file}: 已废止的版本必须填写 effective_to")

    walk(doc["provisions"], set(), errors, file)
    return errors


def main() -> int:
    files = [f for f in (ROOT / "data").rglob("*.json") if "schema" not in f.parts]
    all_errors = [e for f in files for e in check(f)]
    for e in all_errors:
        print("✗", e)
    print(f"\n校验 {len(files)} 个文件，{len(all_errors)} 个错误")
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
