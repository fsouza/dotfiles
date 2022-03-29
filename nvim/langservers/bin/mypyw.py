import os
import sys
import tempfile
from pathlib import Path
from typing import NoReturn


def main(args: list[str]) -> NoReturn:
    src_file_name = args.pop()

    mypy_exe = os.getenv("MYPY_EXE")
    if mypy_exe is None:
        mypy_exe = relative_mypy()

    _, shadow_file = tempfile.mkstemp()
    with open(shadow_file, "wb") as f:
        for line in sys.stdin.buffer:
            f.write(line)

    os.execl(
        mypy_exe,
        mypy_exe,
        *args,
        "--shadow-file",
        src_file_name,
        shadow_file,
        src_file_name,
    )


def relative_mypy() -> str:
    executable = Path(sys.executable)
    mypy_executable = executable.parent / "mypy"
    if not mypy_executable.exists():
        raise ValueError(
            f"cannot find mypy next to {sys.executable}, please specify MYPY_EXE",
        )

    return str(mypy_executable)


if __name__ == "__main__":
    main(sys.argv[1:])
