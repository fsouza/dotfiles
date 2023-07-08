import asyncio
import os
import shutil
import sys
import venv
from asyncio.tasks import Task
from pathlib import Path
from typing import Literal
from typing import overload

base_dir = (Path(__file__).parent / "..").absolute()


class CommandError(Exception):
    ...


async def exists(path: Path) -> bool:
    return await asyncio.to_thread(path.exists)


async def has_command(cmd: str) -> bool:
    return bool(await asyncio.to_thread(lambda: shutil.which(cmd)))


async def write_file(path: Path, contents: str) -> None:
    await asyncio.to_thread(path.write_text, contents)


async def write_bytes(path: Path, contents: bytes) -> None:
    await asyncio.to_thread(path.write_bytes, contents)


@overload
async def run_cmd(
    cmd: str | os.PathLike,
    args: list[object],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    ignore_errors: bool = False,
    capture_output: Literal[False] = False,
    stdin: bytes | None = None,
) -> None:
    ...


@overload
async def run_cmd(
    cmd: str | os.PathLike,
    args: list[object],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    ignore_errors: bool = False,
    capture_output: Literal[True] = True,
    stdin: bytes | None = None,
) -> tuple[bytes, bytes]:
    ...


async def run_cmd(
    cmd: str | os.PathLike,
    args: list[object],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    ignore_errors: bool = False,
    capture_output: bool = False,
    stdin: bytes | None = None,
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
        stdin=asyncio.subprocess.PIPE,
        cwd=cwd,
        env={
            **os.environ,
            **(env or {}),
        },
    )

    stdout, stderr = await proc.communicate(stdin)
    assert proc.returncode is not None

    returncode = proc.returncode
    if returncode != 0:
        if capture_output:
            sys.stdout.buffer.write(stdout)
            sys.stderr.buffer.write(stderr)

        if ignore_errors:
            return

        raise CommandError(
            f"command '{cmd} {' '.join(str_args)}' exited with status {returncode}",
        )

    if capture_output:
        return stdout, stderr


async def ensure_virtualenv(cache_dir: Path) -> Path:
    venv_dir = cache_dir / "venv"

    if not await exists(venv_dir):
        await asyncio.to_thread(venv.create, venv_dir, with_pip=True, symlinks=False)

    await run_cmd(
        venv_dir / "bin" / "pip",
        [
            "install",
            "--upgrade",
            "pip",
            "pip-tools",
        ],
    )

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
        here_rocks_url = (
            "https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py"
        )
        await run_cmd(
            "curl",
            [
                "-sLo",
                filename,
                here_rocks_url,
            ],
        )

    return filename


async def _neovim_lua_command(cmd: bytes) -> str:
    # in an ideal world, we'd start neovim's tcp server and communicate using
    # the API, but that depends on msgpack, and this script should work with
    # stuff that's defined in Python's standard library.

    _, stderr = await run_cmd(
        "nvim",
        [
            "--clean",
            "-l",
            "-",
        ],
        capture_output=True,
        stdin=cmd,
    )

    return stderr.decode().strip()


async def _find_luajit_version() -> str:
    command = rb"""local luajit_version = string.gsub(jit.version, "LuaJIT ", "")
print(luajit_version)
"""

    return await _neovim_lua_command(command)


async def ensure_hererocks(cache_dir: Path) -> Path:
    hr_dir = cache_dir / "hr"

    if not await exists(hr_dir):
        hererocks_py = await download_hererocks_py(cache_dir)
        luajit_version = await _find_luajit_version()
        await run_cmd(
            sys.executable,
            [hererocks_py, "-j", luajit_version, "-r", "latest", hr_dir],
        )

    rocks_dir = os.getenv("HOMEBREW_PREFIX", "/usr/local")

    await run_cmd(
        hr_dir / "bin" / "luarocks",
        ["make", "--force", f"PCRE_DIR={rocks_dir}"],
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

    await run_cmd("fnm", ["install"], cwd=base_dir / "langservers")
    await run_cmd(
        "fnm",
        [
            "exec",
            "npx",
            "--yes",
            "yarn",
            "install",
            "--frozen-lockfile",
        ],
        cwd=base_dir / "langservers",
    )


async def install_ocaml_lsp() -> None:
    if not await has_command("opam"):
        print("skipping ocaml-lsp")
        return

    await run_cmd(
        "opam",
        [
            "install",
            "-y",
            "ocaml-lsp-server",
            "ocamlformat",
        ],
    )


async def install_gopls(langservers_cache_dir: Path) -> None:
    if not await has_command("go"):
        print("skipping gopls")
        return

    repo_dir = await _clone_or_update(
        "https://github.com/golang/tools.git",
        langservers_cache_dir / "tools",
    )

    await run_cmd(
        "go",
        ["install"],
        env={
            "GOBIN": str(langservers_cache_dir / "bin"),
            "GOPROXY": "https://proxy.golang.org",
        },
        cwd=repo_dir / "gopls",
    )


async def install_rust_analyzer(langservers_cache_dir: Path) -> None:
    if not await has_command("rustup"):
        print("skipping rust-analyzer")
        return

    uname = await asyncio.to_thread(os.uname)
    machine = uname.machine
    arch = "aarch64" if machine == "arm64" else machine
    sysname = uname.sysname.lower()
    os_name = "gnu" if sysname == "linux" else sysname
    manufacturer = "apple" if os_name == "darwin" else "unknown-linux"

    url = (
        "https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/"
        f"rust-analyzer-{arch}-{manufacturer}-{os_name}.gz"
    )

    # note: this is horrible
    [_, (stdout, _)] = await asyncio.gather(
        run_cmd(cmd="rustup", args=["component", "add", "rust-src"]),
        run_cmd(
            cmd="bash",
            args=["-c", f"curl -sL {url} | gunzip -c -"],
            capture_output=True,
        ),
    )

    target_bin = langservers_cache_dir / "bin" / "rust-analyzer"
    await asyncio.to_thread(target_bin.parent.mkdir, parents=True, exist_ok=True)
    await write_bytes(target_bin, stdout)
    await asyncio.to_thread(target_bin.chmod, 0o700)


rtx_java_plugin_task: Task[None] | None = None


async def _ensure_java_rtx() -> None:
    async def _add_and_update_java() -> None:
        await run_cmd("rtx", ["plugin", "add", "java"])
        await run_cmd("rtx", ["plugin", "update", "java"])

    # this is ugly
    global rtx_java_plugin_task
    if rtx_java_plugin_task is None:
        rtx_java_plugin_task = asyncio.create_task(_add_and_update_java())

    await rtx_java_plugin_task


async def _get_java_home(version: str) -> str:
    await _ensure_java_rtx()

    tool = f"java@{version}"
    await run_cmd("rtx", ["install", tool])

    stdout, _ = await run_cmd("rtx", ["where", tool], capture_output=True)
    return stdout.decode().strip()


async def install_jdtls(langservers_cache_dir: Path) -> None:
    if not await has_command("rtx"):
        print("skipping jdtls")
        return

    target_dir = langservers_cache_dir / "jdtls"
    await asyncio.to_thread(target_dir.mkdir, parents=True, exist_ok=True)

    jdtls_url = (
        "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz"
    )
    lombok_url = "https://projectlombok.org/downloads/lombok.jar"
    print(f"#{target_dir}#")
    await asyncio.gather(
        run_cmd(
            cmd="bash",
            args=["-c", f"curl -sL {jdtls_url} | tar -C {target_dir} -xzf -"],
        ),
        run_cmd(
            cmd="bash",
            args=["-c", f"curl -sLo {target_dir}/lombok.jar {lombok_url}"],
        ),
        _clone_or_update(
            "https://github.com/dgileadi/vscode-java-decompiler.git",
            target_dir / "vscode-java-decompiler",
        ),
    )


async def install_kotlin_language_server(langservers_cache_dir: Path) -> None:
    if not await has_command("rtx"):
        print("skipping kotlin-language-server")
        return

    repo_dir = await _clone_or_update(
        "https://github.com/fwcd/kotlin-language-server.git",
        langservers_cache_dir / "kotlin-language-server",
    )

    java_home = await _get_java_home("corretto-17")
    await run_cmd(
        cmd="./gradlew",
        args=["-PjavaVersion=17", ":server:installDist"],
        cwd=repo_dir,
        env={
            "JAVA_HOME": java_home,
        },
    )


async def install_groovy_language_server(langservers_cache_dir: Path) -> None:
    if not await has_command("rtx"):
        print("skipping groovy-language-server")
        return

    repo_dir = await _clone_or_update(
        "https://github.com/GroovyLanguageServer/groovy-language-server.git",
        langservers_cache_dir / "groovy-language-server",
    )

    java_home = await _get_java_home("corretto-11")
    print(java_home)
    await run_cmd(
        cmd="./gradlew",
        args=["build"],
        cwd=repo_dir,
        env={
            "JAVA_HOME": java_home,
        },
    )


async def setup_langservers(cache_dir: Path) -> None:
    langservers_cache_dir = cache_dir / "langservers"
    await asyncio.gather(
        install_servers_from_npm(),
        install_ocaml_lsp(),
        install_gopls(langservers_cache_dir),
        install_rust_analyzer(langservers_cache_dir),
        install_jdtls(langservers_cache_dir),
        install_kotlin_language_server(langservers_cache_dir),
        install_groovy_language_server(langservers_cache_dir),
    )


async def setup_fnlfmt(cache_dir: Path, hr_dir: Path) -> None:
    repo_dir = await _clone_or_update(
        "https://git.sr.ht/~technomancy/fnlfmt",
        cache_dir / "fnlfmt",
    )

    await run_cmd(
        "make",
        [],
        cwd=repo_dir,
        env={"PATH": f"{hr_dir}/bin:{os.environ['PATH']}"},
    )


async def _find_cache_dir() -> Path:
    cache_dir = await _neovim_lua_command(rb"print(vim.fn.stdpath('cache'))")
    return Path(cache_dir)


async def _find_data_dir() -> Path:
    cache_dir = await _neovim_lua_command(rb"print(vim.fn.stdpath('data'))")
    return Path(cache_dir)


async def update_neovim_plugins() -> None:
    data_dir = await _find_data_dir()
    pack_dir = data_dir / "site" / "pack" / "mr"
    mrconfig = base_dir / "scripts" / "mrconfig"

    await asyncio.to_thread(pack_dir.parent.mkdir, parents=True, exist_ok=True)
    if not await exists(pack_dir):
        await run_cmd(
            "mr",
            [
                "-t",
                "-j",
                "bootstrap",
                mrconfig.absolute(),
                pack_dir,
            ],
            cwd=pack_dir.parent,
        )
    else:
        await run_cmd(
            "mr",
            [
                "-t",
                "-j",
                "update",
            ],
            cwd=pack_dir,
        )


async def main() -> int:
    cache_dir = await _find_cache_dir()

    [_, _, hr_dir] = await asyncio.gather(
        setup_langservers(cache_dir),
        ensure_virtualenv(cache_dir),
        ensure_hererocks(cache_dir),
    )

    await setup_fnlfmt(cache_dir, hr_dir)
    await update_neovim_plugins()

    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
