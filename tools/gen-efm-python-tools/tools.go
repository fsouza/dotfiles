package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/alessio/shellescape"
)

var defaultRootmarkers = []string{".git", ""}

func flake8(args []string) []Language {
	const outputFormat = `%(path)s:%(row)d:%(col)d: %(code)s %(text)s`
	flake8 := getPythonBin("flake8")
	return []Language{
		{
			LintCommand: fmt.Sprintf(
				`%s --stdin-display-name ${INPUT} --format %q %s -`,
				flake8,
				outputFormat,
				processArgs(args),
			),
			LintSource:         "flake8",
			LintFormats:        []string{"%f:%l:%c: %m"},
			LintIgnoreExitCode: true,
			LintStdin:          true,
			LintAfterOpen:      true,
			RootMarkers:        append([]string{".flake8"}, defaultRootmarkers...),
		},
	}
}

func autoflake(_ []string) []Language {
	return stdinFormatter("autoflake", []string{
		"--expand-star-imports",
		"--remove-all-unused-imports",
	})
}

func black(args []string) []Language {
	args = append([]string{"--fast", "--quiet"}, args...)
	return stdinFormatter("black", args)
}

func addTrailingComma(args []string) []Language {
	args = append([]string{"--exit-zero-even-if-changed"}, args...)
	return stdinFormatter("add-trailing-comma", args)
}

func reorderPythonImports(args []string) []Language {
	args = append([]string{"--exit-zero-even-if-changed"}, args...)
	return stdinFormatter("reorder-python-imports", args)
}

func pyupgrade(args []string) []Language {
	args = append([]string{"--exit-zero-even-if-changed"}, args...)
	return stdinFormatter("pyupgrade", args)
}

func autopep8(args []string) []Language {
	return stdinFormatter("autopep8", args)
}

func isort(args []string) []Language {
	return stdinFormatter("isort", args)
}

func ruff(_ []string) []Language {
	ruff := getPythonBin("ruff")
	ruffRootmarkers := append([]string{"pyproject.toml", "ruff.toml"}, defaultRootmarkers...)

	return []Language{
		{
			LintCommand:        fmt.Sprintf("%s check --stdin-filename ${INPUT} -", ruff),
			LintSource:         "ruff",
			LintFormats:        []string{"%f:%l:%c: %m"},
			LintStdin:          true,
			LintIgnoreExitCode: true,
			LintAfterOpen:      true,
			RootMarkers:        ruffRootmarkers,
		},
		{
			FormatCommand: fmt.Sprintf("%s check --silent --exit-zero --fix-only -", ruff),
			FormatStdin:   true,
			RootMarkers:   ruffRootmarkers,
		},
		{
			FormatCommand: fmt.Sprintf("%s format -", ruff),
			FormatStdin:   true,
			RootMarkers:   ruffRootmarkers,
		},
	}
}

func stdinFormatter(tool string, args []string) []Language {
	tool = getPythonBin(tool)
	return []Language{
		{
			FormatCommand: fmt.Sprintf("%s %s -", tool, processArgs(args)),
			FormatStdin:   true,
			RootMarkers:   defaultRootmarkers,
		},
	}
}

func processArgs(args []string) string {
	return shellescape.QuoteCommand(args)
}

func getPythonBin(name string) string {
	if virtualenv, ok := os.LookupEnv("VIRTUAL_ENV"); ok {
		candidate := filepath.Join(virtualenv, "bin", name)
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	return filepath.Join(nvimVenvDir, "bin", name)
}
