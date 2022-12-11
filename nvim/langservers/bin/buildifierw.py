import os
import sys
from collections.abc import Sequence
from typing import NoReturn


def main(args: Sequence[str]) -> NoReturn:
    file_type = get_type(args)

    cache_dir = os.getenv("NVIM_CACHE_DIR")
    if cache_dir is None:
        raise ValueError("missing NVIM_CACHE_DIR")

    os.execl(
        f"{cache_dir}/langservers/bin/buildifier",
        f"{cache_dir}/langservers/bin/buildifier",
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
