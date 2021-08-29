from __future__ import annotations

import asyncio
import os
import shutil
import sys
from pathlib import Path
from typing import Literal
from typing import overload

base_dir = (Path(__file__).parent / "..").absolute()


class CommandError(Exception):
    ...


async def exists(path: Path) -> bool:
    return await asyncio.to_thread(path.exists)


async def has_command(cmd: str) -> bool:
    return bool(await asyncio.to_thread(shutil.which, cmd))


@overload
async def run_cmd(
    cmd: str | os.PathLike,
    args: list[object],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    capture_output: Literal[False] = False,
) -> None:
    ...


@overload
async def run_cmd(
    cmd: str | os.PathLike,
    args: list[object],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    capture_output: Literal[True] = True,
) -> tuple[bytes, bytes]:
    ...


async def run_cmd(
    cmd: str | os.PathLike,
    args: list[object],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    capture_output: bool = False,
) -> tuple[bytes, bytes] | None:
    stdout, stderr = sys.stdout, sys.stderr

    if capture_output:
        stdout = asyncio.subprocess.PIPE
        stderr = asyncio.subprocess.PIPE

    str_args = [str(arg) for arg in args]
    proc = await asyncio.create_subprocess_exec(
        cmd,
        *str_args,
        stdout=stdout,
        stderr=stderr,
        cwd=cwd,
        env={
            **os.environ,
            **(env or {}),
        },
    )

    stdout, stderr = await proc.communicate()
    assert proc.returncode is not None

    returncode = proc.returncode
    if returncode != 0:
        raise CommandError(
            f"command '{cmd} {' '.join(str_args)}' exited with status {returncode}",
        )

    if capture_output:
        return stdout, stderr


async def ensure_virtualenv(cache_dir: Path) -> Path:
    venv_dir = cache_dir / "venv"

    if not await exists(venv_dir):
        await run_cmd("python3", ["-m", "venv", venv_dir])

    await run_cmd(
        venv_dir / "bin" / "pip",
        [
            "install",
            "--upgrade",
            "-r",
            base_dir / "langservers" / "requirements.txt",
        ],
    )

    return venv_dir


async def download_hererocks_py(cache_dir: Path) -> Path:
    filename = cache_dir / "hererocks.py"

    if not await exists(filename):
        await run_cmd(
            "curl",
            [
                "-sLo",
                filename,
                "https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py",
            ],
        )

    return filename


async def _neovim_command(cmd: str) -> str:
    # in an ideal world, we'd start neovim's tcp server and communicate using
    # the API, but that depends on msgpack, and this script should work with
    # stuff that's defined in Python's standard library.

    _, stderr = await run_cmd(
        "nvim",
        [
            "--clean",
            "--headless",
            "-E",
            "-u",
            "NORC",
            "-R",
            "-c",
            cmd,
            "-c",
            "qa",
        ],
        capture_output=True,
    )

    return stderr.decode()


async def _find_luajit_version() -> str:
    return await _neovim_command(
        r"lua v = string.gsub(jit.version, 'LuaJIT ', ''); print(v)",
    )


async def ensure_hererocks(cache_dir: Path) -> Path:
    hr_dir = cache_dir / "hr"

    if not await exists(hr_dir):
        hererocks_py = await download_hererocks_py(cache_dir)
        luajit_version = await _find_luajit_version()
        await run_cmd(
            "python3",
            [hererocks_py, "-j", luajit_version, "-r", "latest", hr_dir],
        )

    await run_cmd(
        hr_dir / "bin" / "luarocks",
        ["make", "--server=https://luarocks.org/dev"],
        cwd=base_dir,
    )

    return hr_dir


async def _clone_or_update(repo_url: str, repo_dir: Path) -> Path:
    if not await exists(repo_dir):
        await run_cmd("git", ["clone", "--recurse-submodules", repo_url, repo_dir])

    await run_cmd("git", ["-C", repo_dir, "pull"])
    await run_cmd(
        "git",
        ["-C", repo_dir, "submodule", "update", "--init", "--recursive"],
    )

    return repo_dir


async def install_servers_from_npm() -> None:
    if not await has_command("fnm"):
        print("skipping servers from npm")
        return

    await run_cmd("fnm", ["install", "v16"])
    await run_cmd(
        "fnm",
        [
            "exec",
            "--using=v16",
            "npx",
            "--yes",
            "yarn",
            "install",
            "--frozen-lockfile",
        ],
        cwd=base_dir / "langservers",
    )


async def install_ocaml_lsp(langservers_cache_dir: Path) -> None:
    if not await has_command("opam"):
        print("skipping ocaml-lsp")
        return

    [_, repo_dir] = await asyncio.gather(
        run_cmd("opam", ["update", "-y"]),
        _clone_or_update(
            "https://github.com/ocaml/ocaml-lsp.git",
            langservers_cache_dir / "ocaml-lsp",
        ),
    )
    assert repo_dir is not None

    await run_cmd("opam", ["install", "-y", "ocamlformat"]),
    await run_cmd("opam", ["install", "--deps-only", "-y", "."], cwd=repo_dir)
    await run_cmd("dune", ["build", "@install"], cwd=repo_dir)


async def _go_install(
    langservers_cache_dir: Path,
    *pkgs: str,
    cwd: Path | None = None,
) -> None:
    if not await has_command("go"):
        print(f"skipping go packages: {pkgs}")
        return

    await run_cmd(
        "go",
        ["install", *pkgs],
        env={"GOBIN": str(langservers_cache_dir / "bin")},
        cwd=cwd,
    )


async def install_gopls(langservers_cache_dir: Path) -> None:
    if not await has_command("go"):
        print("skipping gopls")
        return

    repo_dir = await _clone_or_update(
        "https://github.com/golang/tools.git",
        langservers_cache_dir / "tools",
    )

    await _go_install(
        langservers_cache_dir,
        cwd=repo_dir / "gopls",
    )


async def install_shfmt(langservers_cache_dir: Path) -> None:
    await _go_install(langservers_cache_dir, "mvdan.cc/sh/v3/cmd/shfmt@master")


async def install_efm(langservers_cache_dir: Path) -> None:
    await _go_install(langservers_cache_dir, "github.com/mattn/efm-langserver@master")


async def setup_langservers(cache_dir: Path) -> None:
    langservers_cache_dir = cache_dir / "langservers"
    await asyncio.gather(
        install_servers_from_npm(),
        install_ocaml_lsp(langservers_cache_dir),
        install_gopls(langservers_cache_dir),
        install_shfmt(langservers_cache_dir),
        install_efm(langservers_cache_dir),
    )


async def _find_cache_dir() -> Path:
    cache_dir = await _neovim_command("echo stdpath('cache')")
    return Path(cache_dir)


async def main() -> int:
    cache_dir = await _find_cache_dir()

    await asyncio.gather(
        setup_langservers(cache_dir),
        ensure_virtualenv(cache_dir),
        ensure_hererocks(cache_dir),
    )

    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
