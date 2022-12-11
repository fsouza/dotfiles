import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


def main(args: Sequence[str]) -> int:
    gradlew = Path("gradlew").absolute()
    fileName = Path(args[0]).absolute()
    contents = sys.stdin.buffer.read()

    process = subprocess.Popen(
        [
            gradlew,
            "spotlessApply",
            f"-PspotlessIdeHook={fileName}",
            "-PspotlessIdeHookUseStdIn",
            "-PspotlessIdeHookUseStdOut",
            "--quiet",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    stdout, stderr = process.communicate(contents)

    if process.returncode != 0:
        sys.stdout.buffer.write(stdout)
        sys.stderr.buffer.write(stderr)
        return process.returncode

    match stderr:
        case b"IS DIRTY":
            sys.stdout.buffer.write(stdout)
            return 0
        case b"DID NOT CONVERGE":
            sys.stderr.buffer.write(stderr)
            return 1
        case b"" | b"IS CLEAN":
            sys.stdout.buffer.write(contents)
            return 0
        case _:
            sys.stdout.buffer.write(stdout or b"")
            sys.stderr.buffer.write(stderr or b"")
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
