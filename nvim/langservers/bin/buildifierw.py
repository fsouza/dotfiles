import os
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import NoReturn


def main(args: Sequence[str]) -> NoReturn:
    file_type = get_type(args)
    mod_dir = Path(os.environ["FSOUZA_DOTFILES_DIR"]) / "nvim" / "langservers"

    os.execlp(
        "go",
        "go",
        "run",
        "-C",
        mod_dir,
        "github.com/bazelbuild/buildtools/buildifier",
        "--lint=fix",
        "--warnings=all",
        f"--type={file_type}",
    )


def get_type(args: Sequence[str]) -> str:
    filename = os.path.basename(args[0] if args else "")

    name_to_type = {
        "BUILD": "build",
        "WORKSPACE": "workspace",
    }

    return name_to_type.get(filename, "default")


if __name__ == "__main__":
    main(sys.argv)
