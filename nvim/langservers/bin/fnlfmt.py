import os
import subprocess
import sys
from collections.abc import Sequence


def main(args: Sequence[str]) -> int:
    cache_dir = os.getenv("NVIM_CACHE_DIR")
    if cache_dir is None:
        raise ValueError("missing NVIM_CACHE_DIR")

    cmd = subprocess.run(
        [
            f"{cache_dir}/fnlfmt/fnlfmt",
            *args,
        ],
        capture_output=True,
        env={
            **os.environ,
            "PATH": f"{cache_dir}/hr/bin:{os.getenv('PATH')}",
        },
    )

    if cmd.returncode != 0:
        sys.stderr.buffer.write(cmd.stderr)
        return cmd.returncode

    lines = cmd.stdout.splitlines(keepends=True)
    last = len(lines) - 1
    while last >= 0 and lines[last].strip() == b"":
        last -= 1

    sys.stdout.buffer.write(b"".join(lines[: last + 1]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
