from __future__ import annotations

import argparse
import asyncio
import pathlib
import sys

base_dir = (pathlib.Path(__file__).parent / "..").absolute()

HEREROCKS_URL = (
    "https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py"
)


class CommandError(Exception):
    ...


async def exists(path: pathlib.Path) -> bool:
    return await asyncio.get_event_loop().run_in_executor(None, path.exists)


async def run_cmd(cmd: str, args: list[object]) -> None:
    str_args = [str(arg) for arg in args]
    proc = await asyncio.create_subprocess_exec(
        cmd,
        *str_args,
        stdout=sys.stdout,
        stderr=sys.stderr,
    )

    returncode = await proc.wait()
    if returncode != 0:
        raise CommandError(
            f"command 'f{cmd} {''.join(str_args)}' exited with status {returncode}",
        )


async def ensure_virtualenv(cache_dir: pathlib.Path) -> pathlib.Path:
    venv_dir = cache_dir / "venv"

    if not await exists(venv_dir):
        await run_cmd("python3", ["-m", "venv", venv_dir])

    await run_cmd(
        f"{venv_dir}/bin/pip",
        [
            "install",
            "--upgrade",
            "-r",
            base_dir / "langservers" / "requirements.txt",
        ],
    )

    return venv_dir


async def download_hererocks_py(cache_dir: pathlib.Path) -> pathlib.Path:
    filename = cache_dir / "hererocks.py"

    if not await exists(filename):
        await run_cmd("curl", ["-sLo", filename, HEREROCKS_URL])

    return filename


async def ensure_hererocks(cache_dir: pathlib.Path) -> pathlib.Path:
    hr_dir = cache_dir / "hr"

    if not await exists(hr_dir):
        hererocks_py = await download_hererocks_py(cache_dir)
        await run_cmd(
            "python3",
            [hererocks_py, "-j", "latest", "-r", "latest", hr_dir],
        )

    return hr_dir


async def setup_langservers(cache_dir: pathlib.Path) -> None:
    # TODO: migrate this shell script to Python.
    await run_cmd(
        f"{base_dir}/langservers/setup.sh",
        [cache_dir / "langservers"],
    )


async def try_bat_cache_build() -> None:
    try:
        await run_cmd("bat", ["cache", "--build"])
    except CommandError:
        pass


async def main(cache_dir: pathlib.Path) -> int:
    await asyncio.gather(
        setup_langservers(cache_dir),
        ensure_virtualenv(cache_dir),
        ensure_hererocks(cache_dir),
        try_bat_cache_build(),
    )

    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="bootstrap neovim config")
    parser.add_argument(
        "--cache-dir",
        type=pathlib.Path,
        dest="cache_dir",
        required=True,
    )
    args = parser.parse_args()
    args.cache_dir.mkdir(parents=True, exist_ok=True)

    sys.exit(asyncio.run(main(args.cache_dir)))
