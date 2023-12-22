package main

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/fsouza/dotfiles/tools"
)

const virtualenvURL = "https://bootstrap.pypa.io/virtualenv.pyz"

func ensureVirtualenv(nv *Neovim, venvDir string) error {
	pip := filepath.Join(venvDir, "bin", "pip3")
	if _, err := os.Stat(pip); err != nil {
		venvPyz, err := ensureVirtualenvPyz(nv)
		if err != nil {
			return err
		}

		os.RemoveAll(venvDir)
		err = tools.Run(&tools.RunOptions{
			Cmd:  python(),
			Args: []string{venvPyz, venvDir},
		})
		if err != nil {
			return err
		}
	}

	err := tools.Run(&tools.RunOptions{
		Cmd:  pip,
		Args: []string{"install", "--upgrade", "pip", "pip-tools"},
	})
	if err != nil {
		return err
	}

	return tools.Run(&tools.RunOptions{
		Cmd: pip,
		Args: []string{
			"install",
			"--upgrade",
			"-r",
			filepath.Join(dotfilesDir, "nvim", "langservers", "requirements.txt"),
		},
	})
}

func ensureVirtualenvPyz(nv *Neovim) (string, error) {
	outputFile := filepath.Join(nv.CacheDir, "virtualenv.pyz")
	if _, err := os.Stat(outputFile); os.IsNotExist(err) {
		err = tools.DownloadFile(virtualenvURL, outputFile, 0o644)
		return outputFile, err
	}
	return outputFile, nil
}

func python() string {
	python := os.Getenv("PYTHON")
	if python == "" {
		return getPythonFromRtx()
	}
	return python
}

func getPythonFromRtx() string {
	const py = "python@3.12"
	output, err := exec.Command("rtx", "where", py).CombinedOutput()
	if err != nil {
		err = tools.Run(&tools.RunOptions{
			Cmd:  "rtx",
			Args: []string{"install", py},
		})
		if err != nil {
			panic(err)
		}

		output, err = exec.Command("rtx", "where", py).CombinedOutput()
		if err != nil {
			panic(err)
		}
	}

	return filepath.Join(string(bytes.TrimSpace(output)), "bin", "python3")
}
