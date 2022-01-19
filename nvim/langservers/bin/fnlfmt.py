import os
import sys
from collections.abc import Sequence
from typing import NoReturn


def main(args: Sequence[str]) -> NoReturn:
    cache_dir = os.getenv("NVIM_CACHE_DIR")
    if cache_dir is None:
        raise ValueError("missing NVIM_CACHE_DIR")

    os.execl(
        f"{cache_dir}/fnlfmt/fnlfmt",
        *args,
    )


if __name__ == "__main__":
    main(sys.argv[1:])
