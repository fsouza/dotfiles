import os
import pathlib
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


def main(args: Sequence[str]) -> int:
    fennel = os.environ["FENNEL"]
    [fnl_file, out_file] = args

    macros_file = Path(__file__).parent.parent / "macros" / "init.fnl"

    cmd = subprocess.run(
        [
            fennel,
            "--load",
            str(macros_file.absolute()),
            "--globals",
            "vim,dotfiles-dir,config-dir,cache-dir,data-dir,hs",
            "--raw-errors",
            "-c",
            fnl_file,
        ],
        capture_output=True,
    )
    if cmd.returncode != 0:
        sys.stderr.buffer.write(cmd.stderr)
        return cmd.returncode

    lua_file = pathlib.Path(out_file)
    lua_file.parent.mkdir(parents=True, exist_ok=True)
    lua_file.write_bytes(cmd.stdout)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
