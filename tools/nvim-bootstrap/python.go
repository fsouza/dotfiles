package main

import (
	"os"
	"path/filepath"

	"github.com/fsouza/dotfiles/tools"
)

const virtualenvURL = "https://bootstrap.pypa.io/virtualenv.pyz"

func ensureVirtualenv(nv *Neovim) error {
	venvDir := filepath.Join(nv.CacheDir, "venv")
	if _, err := os.Stat(venvDir); err != nil {
		venvPyz, err := ensureVirtualenvPyz(nv)
		if err != nil {
			return err
		}

		err = tools.Run(&tools.RunOptions{
			Cmd:  python(),
			Args: []string{venvPyz, venvDir},
		})
		if err != nil {
			return err
		}
	}

	pip := filepath.Join(venvDir, "bin", "pip")
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
		return "python3"
	}
	return python
}
