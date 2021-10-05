import os
import pathlib
import sys
from collections.abc import Sequence
from typing import NoReturn


def main(args: Sequence[str]) -> NoReturn:
    root_dir = pathlib.Path(__file__).parent.parent.absolute()
    os.chdir(root_dir)
    os.execlp("fnm", "fnm", "exec", "npx", "--no-install", *args[1:])


if __name__ == "__main__":
    main(sys.argv)
