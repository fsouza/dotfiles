#!/usr/bin/env python3
import os
import subprocess
import sys
import tempfile


def main() -> int:
    lines = sys.stdin.buffer.readlines()

    if os.getenv("EDITOR") == "nvim" and should_send_to_nvim(lines):
        return send_to_nvim(b"".join(lines))
    else:
        return copy(b"".join(lines))


def should_send_to_nvim(lines: list[bytes]) -> bool:
    print(lines)
    return any(line for line in lines)


def send_to_nvim(contents: bytes) -> int:
    fd, path = tempfile.mkstemp()
    os.write(fd, contents)
    os.close(fd)

    nvim_command = f"lua require('fsouza.plugin.tmux-selection').handle('{path}')"
    proc = subprocess.run(["tmux", "send-keys", f'nvim -c "{nvim_command}"'])
    if proc.returncode != 0:
        return proc.returncode

    return subprocess.run(["tmux", "send-keys", "C-m"]).returncode


def copy(contents: bytes) -> int:
    command = os.environ["TMUX_COPY_CMD"]

    with tempfile.TemporaryFile() as f:
        f.write(contents.rstrip())
        f.seek(0, os.SEEK_SET)

        proc = subprocess.run([command], stdin=f)
        return proc.returncode


if __name__ == "__main__":
    sys.exit(main())
