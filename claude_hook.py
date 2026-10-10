"""Claude Code PostToolUse hook: bir skill/mod/ajan dosyası yazılınca SkillSpector ile tarar.

Yalnızca statik tarama (--no-llm) yapar. Sorun bulunursa Claude'a geri bildirim verir;
temizse sessiz kalır.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

SKILLSPECTOR = Path(__file__).resolve().parent / ".venv" / "Scripts" / "skillspector.exe"
# Bu klasörlerin altındaki dosyalar "skill/mod" sayılır.
WATCHED_DIRS = {"skills", "mods", "agents", "commands", "plugins"}
# Kendi kaynak kodumuzdaki test örneklerini taramayalım.
SELF_ROOT = Path(__file__).resolve().parent


def find_target(file_path: Path) -> Path | None:
    """Dosyanın ait olduğu skill/mod kökünü bulur; izlenen bir yerde değilse None."""
    try:
        file_path.resolve().relative_to(SELF_ROOT)
        return None
    except ValueError:
        pass
    parts = [p.lower() for p in file_path.parts]
    for i in range(len(parts) - 1, -1, -1):
        if parts[i] in WATCHED_DIRS:
            rest = file_path.parts[i + 1 :]
            if len(rest) <= 1:
                # skills/foo.md gibi tek dosya
                return file_path
            return Path(*file_path.parts[: i + 2])
    if file_path.name.upper() == "SKILL.MD":
        return file_path.parent
    return None


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    tool_input = data.get("tool_input") or {}
    raw = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not raw:
        return 0
    target = find_target(Path(raw))
    if target is None or not target.exists() or not SKILLSPECTOR.exists():
        return 0

    fd, out = tempfile.mkstemp(suffix=".json")
    os.close(fd)
    try:
        env = dict(os.environ, PYTHONIOENCODING="utf-8")
        subprocess.run(
            [str(SKILLSPECTOR), "scan", str(target), "--no-llm", "--format", "json", "--output", out],
            capture_output=True,
            timeout=120,
            env=env,
        )
        report = json.loads(Path(out).read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"SkillSpector taraması çalışmadı ({target}): {exc}", file=sys.stderr)
        return 0
    finally:
        Path(out).unlink(missing_ok=True)

    risk = report.get("risk_assessment") or {}
    issues = report.get("issues") or []
    if not issues:
        return 0

    lines = [
        f"SkillSpector uyarısı: {target}",
        f"Risk: {risk.get('score')}/100, {risk.get('severity')}, öneri: {risk.get('recommendation')}",
    ]
    for issue in issues[:8]:
        loc = issue.get("location") or {}
        lines.append(
            f"- [{issue.get('severity')}] {issue.get('category')} / {issue.get('pattern')} "
            f"({loc.get('file')}:{loc.get('start_line')}): {issue.get('finding')}"
        )
    if len(issues) > 8:
        lines.append(f"... ve {len(issues) - 8} bulgu daha. Tam rapor için /tara {target}")
    lines.append("Bu bulguları kullanıcıya bildir; HIGH/CRITICAL ise skill'i kullanmadan önce onay al.")
    message = "\n".join(lines)

    severe = risk.get("severity") in {"HIGH", "CRITICAL"}
    if severe:
        print(json.dumps({"decision": "block", "reason": message}, ensure_ascii=False))
    else:
        print(
            json.dumps(
                {"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": message}},
                ensure_ascii=False,
            )
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
