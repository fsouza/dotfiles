from __future__ import annotations

import argparse
import asyncio
import os
import shutil
import sys
from pathlib import Path

base_dir = (Path(__file__).parent / "..").absolute()


class CommandError(Exception):
    ...


async def exists(path: Path) -> bool:
    return await asyncio.to_thread(path.exists)


async def has_command(cmd: str) -> bool:
    return bool(await asyncio.to_thread(shutil.which, cmd))


async def run_cmd(
    cmd: str | os.PathLike,
    args: list[object],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
) -> None:
    str_args = [str(arg) for arg in args]
    proc = await asyncio.create_subprocess_exec(
        cmd,
        *str_args,
        stdout=sys.stdout,
        stderr=sys.stderr,
        cwd=cwd,
        env={
            **os.environ,
            **(env or {}),
        },
    )

    returncode = await proc.wait()
    if returncode != 0:
        raise CommandError(
            f"command 'f{cmd} {''.join(str_args)}' exited with status {returncode}",
        )


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


async def ensure_hererocks(cache_dir: Path) -> Path:
    hr_dir = cache_dir / "hr"

    if not await exists(hr_dir):
        hererocks_py = await download_hererocks_py(cache_dir)
        await run_cmd(
            "python3",
            [hererocks_py, "-j", "latest", "-r", "latest", hr_dir],
        )

    await run_cmd(
        hr_dir / "bin" / "luarocks",
        ["make", "--server=https://luarocks.org/dev"],
        cwd=base_dir,
    )

    return hr_dir


async def _clone_or_update(repo_url: str, repo_dir: Path) -> None:
    if not await exists(repo_dir):
        await run_cmd("git", ["clone", "--recurse-submodules", repo_url, repo_dir])

    await run_cmd("git", ["-C", repo_dir, "pull"])
    await run_cmd(
        "git",
        ["-C", repo_dir, "submodule", "update", "--init", "--recursive"],
    )


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


async def install_ocaml_lsp(cache_dir: Path) -> None:
    if not await has_command("opam"):
        print("skipping ocaml-lsp")
        return

    await run_cmd("opam", ["update", "-y"])
    await run_cmd("opam", ["install", "-y", "dune", "ocamlformat", "ocamlformat-rpc"])

    await _clone_or_update(
        "https://github.com/ocaml/ocaml-lsp.git",
        cache_dir / "ocaml-lsp",
    )
    await run_cmd("make", ["-C", cache_dir / "ocaml-lsp", "all"])


async def _go_install(cache_dir: Path, *pkgs: str, cwd: Path | None = None) -> None:
    if not await has_command("go"):
        print(f"skipping go packages: {pkgs}")
        return

    await run_cmd(
        "go",
        ["install", *pkgs],
        env={"GOBIN": str(cache_dir / "langservers" / "bin")},
        cwd=cwd,
    )


async def install_gopls(cache_dir: Path) -> None:
    if not await has_command("go"):
        print("skipping gopls")
        return

    await _clone_or_update(
        "https://github.com/golang/tools.git",
        cache_dir / "tools",
    )

    await _go_install(cache_dir, cwd=cache_dir / "tools" / "gopls")


async def install_shfmt(cache_dir: Path) -> None:
    await _go_install(cache_dir, "mvdan.cc/sh/v3/cmd/shfmt@master")


async def install_efm(cache_dir: Path) -> None:
    await _go_install(cache_dir, "github.com/mattn/efm-langserver@master")


async def setup_langservers(cache_dir: Path) -> None:
    await asyncio.gather(
        install_servers_from_npm(),
        install_ocaml_lsp(cache_dir),
        install_gopls(cache_dir),
        install_shfmt(cache_dir),
        install_efm(cache_dir),
    )


async def try_bat_cache_build() -> None:
    if not await has_command("bat"):
        print("skipping bat")
        return

    await run_cmd("bat", ["cache", "--build"])


async def main(cache_dir: Path) -> int:
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
        type=Path,
        dest="cache_dir",
        required=True,
    )
    args = parser.parse_args()
    args.cache_dir.mkdir(parents=True, exist_ok=True)

    sys.exit(asyncio.run(main(args.cache_dir)))
