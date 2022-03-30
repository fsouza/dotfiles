import contextlib
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def main(args: list[str]) -> int:
    src_file_name = args.pop()

    mypy_exe = os.getenv("MYPY_EXE")
    if mypy_exe is None:
        mypy_exe = relative_mypy()

    _, shadow_file_name = tempfile.mkstemp()
    with open(shadow_file_name, "wb") as shadow_file:
        for line in sys.stdin.buffer:
            shadow_file.write(line)

    if "--show-column-numbers" not in args:
        args.append("--show-column-numbers")

    cmd = subprocess.run(
        [
            mypy_exe,
            *args,
            "--shadow-file",
            src_file_name,
            shadow_file_name,
            src_file_name,
        ],
    )

    with contextlib.suppress(FileNotFoundError):
        os.unlink(shadow_file_name)

    return cmd.returncode


def relative_mypy() -> str:
    executable = Path(sys.executable)
    mypy_executable = executable.parent / "mypy"
    if not mypy_executable.exists():
        raise ValueError(
            f"cannot find mypy next to {sys.executable}, please specify MYPY_EXE",
        )

    return str(mypy_executable)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
