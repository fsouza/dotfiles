package main

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/fsouza/dotfiles/tools"
)

func ensureVirtualenv(venvDir string) error {
	py3 := filepath.Join(venvDir, "bin", "python3")
	if _, err := os.Stat(py3); err != nil {
		os.RemoveAll(venvDir)
		err = tools.Run(&tools.RunOptions{
			Cmd:  "uv",
			Args: []string{"venv", "--python", python(), venvDir},
		})
		if err != nil {
			return err
		}
	}

	return nil
}

func python() string {
	python := os.Getenv("PYTHON")
	if python == "" {
		return getPythonFromMise()
	}
	return python
}

func getPythonFromMise() string {
	const py = "python@3.12"
	output, err := exec.Command("mise", "where", py).CombinedOutput()
	if err != nil {
		err = tools.Run(&tools.RunOptions{
			Cmd:  "mise",
			Args: []string{"install", py},
		})
		if err != nil {
			panic(err)
		}

		output, err = exec.Command("mise", "where", py).CombinedOutput()
		if err != nil {
			panic(err)
		}
	}

	return filepath.Join(string(bytes.TrimSpace(output)), "bin", "python3")
}
