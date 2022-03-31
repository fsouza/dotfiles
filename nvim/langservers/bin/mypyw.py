import subprocess
import sys
from pathlib import Path


def main(args: list[str]) -> int:
    # discard the source file name
    args.pop()

    dmypy_exe = relative_dmypy()

    default_args = (
        "--show-column-numbers",
        "--ignore-missing-imports",
        "--scripts-are-modules",
    )
    for arg in default_args:
        if arg not in args:
            args.append(arg)

    cmd = subprocess.run(
        [
            dmypy_exe,
            "run",
            "--",
            *args,
            "--exclude",
            "venv",
            "--exclude",
            ".venv",
            ".",
        ],
    )

    return cmd.returncode


def relative_dmypy() -> str:
    executable = Path(sys.executable)
    dmypy_executable = executable.parent / "dmypy"
    if not dmypy_executable.exists():
        raise ValueError(
            f"cannot find dmypy next to {sys.executable}, please install mypy",
        )

    return str(dmypy_executable)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
