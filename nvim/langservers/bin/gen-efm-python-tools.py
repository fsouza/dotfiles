from __future__ import annotations

import asyncio
import dataclasses
import itertools
import json
import os
import shlex
import sys
from collections.abc import Awaitable
from collections.abc import Callable
from collections.abc import Iterable
from collections.abc import Mapping
from collections.abc import Sequence
from dataclasses import dataclass
from dataclasses import field
from pathlib import Path
from typing import NotRequired
from typing import TypeAlias
from typing import TypedDict

import yaml


DEFAULT_ROOT_MARKERS = [".git" ""]


@dataclass
class Formatter:
    formatCommand: str
    formatStdin: bool = True
    rootMarkers: Sequence[str] = field(default_factory=lambda: DEFAULT_ROOT_MARKERS)

    def __hash__(self) -> int:
        return hash(self.formatCommand)


@dataclass
class Linter:
    lintCommand: str
    lintSource: str
    lintFormats: Sequence[str]
    lintIgnoreExitCode: bool = True
    lintStdin: bool = True
    rootMarkers: Sequence[str] = field(default_factory=lambda: DEFAULT_ROOT_MARKERS)

    def __hash__(self) -> int:
        return hash(self.lintCommand)


LinterFactory: TypeAlias = Callable[
    [Sequence[str]],
    Awaitable[tuple[Linter, Formatter]],
]
FormatterFactory: TypeAlias = Callable[[Sequence[str]], Awaitable[Formatter]]


class PrecommitRepo(TypedDict):
    repo: str
    hooks: Sequence[PrecommitHook]


class PrecommitHook(TypedDict):
    id: str  # noqa: A003
    args: NotRequired[Sequence[str]]


async def main() -> int:
    cur_dir = Path.cwd()
    precommit_config: Path | None = None

    for folder in (cur_dir, *cur_dir.parents):
        candidate = folder / ".pre-commit-config.yaml"
        if candidate.exists():
            precommit_config = candidate
            break

    coros: Iterable[Awaitable[Formatter | tuple[Linter, Formatter]]] = []
    if precommit_config is not None:
        coros = from_precommit(precommit_config)
    else:
        coros = [
            get_ruff([]),
            get_black([]),
            get_add_trailing_comma([]),
            get_reorder_python_imports([]),
            get_ruff_fix([]),
        ]

    result: Sequence[Formatter | tuple[Linter, Formatter]] = await asyncio.gather(
        *coros
    )
    tools = itertools.chain.from_iterable(
        [tool] if isinstance(tool, Formatter) else tool for tool in result
    )

    json.dump([dataclasses.asdict(tool) for tool in set(tools)], sys.stdout)
    return 0


def from_precommit(
    file: Path,
) -> Iterable[Awaitable[Formatter | tuple[Linter, Formatter]]]:
    pc_repos = read_precommit_config(file)
    repo_mapping: Mapping[str, LinterFactory | FormatterFactory] = {
        "https://github.com/pycqa/flake8": get_flake8,
        "https://github.com/pycqa/autoflake": get_autoflake,
        "https://github.com/myint/autoflake": get_autoflake,
        "https://github.com/psf/black": get_black,
        "https://github.com/ambv/black": get_black,
        "https://github.com/asottile/add-trailing-comma": get_add_trailing_comma,
        "https://github.com/asottile/reorder-python-imports": get_reorder_python_imports,
        "https://github.com/asottile/reorder_python_imports": get_reorder_python_imports,
        "https://github.com/asottile/pyupgrade": get_pyupgrade,
        "https://github.com/pre-commit/mirrors-autopep8": get_autopep8,
        "https://github.com/pre-commit/mirrors-isort": get_isort,
        "https://github.com/pycqa/isort": get_isort,
        "https://github.com/timothycrosley/isort": get_isort,
        "https://github.com/charliermarsh/ruff-pre-commit": get_ruff,
    }

    output: list[Awaitable[Formatter | tuple[Linter, Formatter]]] = []
    for pc_repo in pc_repos:
        fn = repo_mapping.get(pc_repo["repo"])
        if fn is not None:
            args = next(
                (hook["args"] for hook in pc_repo["hooks"] if "args" in hook),
                [],
            )
            output.append(fn(args))

    return output


def read_precommit_config(file: Path) -> Sequence[PrecommitRepo]:
    # this function blocks the event loop, but it's ok: it's intended to be
    # used before we have concurrent/async work to do.
    with file.open() as f:
        return yaml.load(f, Loader=yaml.SafeLoader)["repos"]


async def get_black(args: Sequence[str]) -> Formatter:
    black = await _get_python_bin("black")
    return Formatter(
        formatCommand=f"{black} --fast --quiet {process_args(args)} -",
    )


async def get_isort(args: Sequence[str]) -> Formatter:
    isort = await _get_python_bin("isort")
    return Formatter(
        formatCommand=f"{isort} {process_args(args)} -",
        rootMarkers=[".isort.cfg", *DEFAULT_ROOT_MARKERS],
    )


async def get_autoflake(args: Sequence[str]) -> Formatter:
    autoflake = await _get_python_bin("autoflake")
    return Formatter(
        formatCommand=f"{autoflake} --expand-star-imports --remove-all-unused-imports -",
    )


async def get_ruff_fix(args: Sequence[str]) -> Formatter:
    ruff = _venv_tool("ruff")
    return Formatter(
        formatCommand=f"{ruff} --silent --exit-zero --fix -",
        rootMarkers=["pyproject.toml", "ruff.toml", *DEFAULT_ROOT_MARKERS],
    )


async def get_add_trailing_comma(args: Sequence[str]) -> Formatter:
    add_trailing_comma = await _get_python_bin("add-trailing-comma")
    return Formatter(
        formatCommand=f"{add_trailing_comma} --exit-zero-even-if-changed {process_args(args)} -",
    )


async def get_reorder_python_imports(args: Sequence[str]) -> Formatter:
    reorder_python_imports = await _get_python_bin("reorder-python-imports")
    return Formatter(
        formatCommand=f"{reorder_python_imports} --exit-zero-even-if-changed {process_args(args)} -",
    )


async def get_autopep8(args: Sequence[str]) -> Formatter:
    autopep8 = await _get_python_bin("autopep8")
    return Formatter(
        formatCommand=f"{autopep8} {process_args(args)} -",
    )


async def get_pyupgrade(args: Sequence[str]) -> Formatter:
    pyupgrade = await _get_python_bin("pyupgrade")
    return Formatter(
        formatCommand=f"{pyupgrade} --exit-zero-even-if-changed {process_args(args)} -",
    )


async def get_flake8(args: Sequence[str]) -> tuple[Linter, Formatter]:
    flake8 = await _get_python_bin("flake8")
    fmt = """ "%(path)s:%(row)d:%(col)d: %(code)s %(text)s" """
    return Linter(
        lintCommand=f"{flake8} --stdin-display-name ${{INPUT}} --format {fmt} {process_args(args)} -",
        lintSource="flake8",
        lintFormats=["%f:%l:%c: %m"],
        rootMarkers=[".flake8", *DEFAULT_ROOT_MARKERS],
    ), await get_autoflake([])


async def get_ruff(args: Sequence[str]) -> tuple[Linter, Formatter]:
    ruff = _venv_tool("ruff")
    return Linter(
        lintCommand=f"{ruff} --stdin-filename ${{INPUT}} -",
        lintSource="ruff",
        lintFormats=["%f:%l:%c: %m"],
        rootMarkers=["pyproject.toml", "ruff.toml", *DEFAULT_ROOT_MARKERS],
    ), await get_ruff_fix([])


async def _get_python_bin(name: str) -> Path:
    venv = os.getenv("VIRTUAL_ENV")
    if venv is not None:
        bin_dir = Path(venv) / "bin" / name
        if await exists(bin_dir):
            return bin_dir

    return _venv_tool(name)


def _venv_tool(name: str) -> Path:
    return Path(sys.executable).parent / name


async def exists(p: Path) -> bool:
    return await asyncio.to_thread(p.exists)


def process_args(args: Sequence[str]) -> str:
    return " ".join(shlex.quote(arg) for arg in args)


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
