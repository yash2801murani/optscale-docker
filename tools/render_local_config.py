#!/usr/bin/env python3
import os
import re
import sys
from pathlib import Path


VAR_PATTERN = re.compile(r"\$\{([A-Z0-9_]+)\}")


def render(template_text: str) -> str:
    missing = sorted({name for name in VAR_PATTERN.findall(template_text) if name not in os.environ})
    if missing:
        raise RuntimeError(f"Missing environment variables for template rendering: {', '.join(missing)}")
    return VAR_PATTERN.sub(lambda match: os.environ[match.group(1)], template_text)


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: render_local_config.py <template> <output>")

    template_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    rendered = render(template_path.read_text(encoding="utf-8"))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
